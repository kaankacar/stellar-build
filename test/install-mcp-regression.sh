#!/usr/bin/env bash
# Regression coverage for installer MCP helpers and ownership/scope behavior.
# Sources the real helpers from install.sh (STELLAR_BUILD_LIB_ONLY).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=mcp-config-helpers.sh
source "$ROOT/test/mcp-config-helpers.sh"

PASS=0
FAIL=0
assert() {
  local name="$1"
  shift
  if "$@"; then
    printf '  PASS  %s\n' "$name"
    PASS=$((PASS + 1))
  else
    printf '  FAIL  %s\n' "$name"
    FAIL=$((FAIL + 1))
  fi
}
assert_eq() {
  local name="$1" got="$2" want="$3"
  if [ "$got" = "$want" ]; then
    printf '  PASS  %s\n' "$name"
    PASS=$((PASS + 1))
  else
    printf '  FAIL  %s\n    got:  %s\n    want: %s\n' "$name" "$got" "$want"
    FAIL=$((FAIL + 1))
  fi
}
assert_file_has() {
  local name="$1" file="$2" needle="$3"
  if grep -qF -- "$needle" "$file"; then
    printf '  PASS  %s\n' "$name"
    PASS=$((PASS + 1))
  else
    printf '  FAIL  %s (missing %s)\n' "$name" "$needle"
    FAIL=$((FAIL + 1))
  fi
}
assert_file_lacks() {
  local name="$1" file="$2" needle="$3"
  if grep -qF -- "$needle" "$file"; then
    printf '  FAIL  %s (unexpected %s)\n' "$name" "$needle"
    FAIL=$((FAIL + 1))
  else
    printf '  PASS  %s\n' "$name"
    PASS=$((PASS + 1))
  fi
}

for fn in codex_mcp_table_re codex_mcp_has_table codex_mcp_remove_table \
          codex_mcp_replace_url_in_table codex_mcp_table_has_url \
          codex_toml_awk_lib claude_json_path claude_user_mcp_has \
          claude_user_mcp_url claude_user_mcp_get_json claude_user_mcp_set_url \
          claude_user_mcp_set_entry manifest_flag_true; do
  assert "install.sh defines $fn" grep -q "^${fn}()" "$ROOT/install.sh"
done
assert "installer uses manifest_flag_true for docs ownership" \
  grep -q 'manifest_flag_true docsMcpClaude' "$ROOT/install.sh"
assert "installer uses manifest_flag_true on uninstall docs" \
  grep -q 'manifest_flag_true docsMcpClaude && has_cmd claude' "$ROOT/install.sh"

WORKDIR="$(mktemp -d)"
trap 'rm -rf "$WORKDIR"' EXIT

echo "== TOML table detection (quoted + unquoted) =="
cfg="$WORKDIR/config.toml"
cat > "$cfg" <<'EOF'
model = "gpt"
[mcp_servers."other"]
command = "npx"
args = ["-y", "mcp-remote", "https://example.com/other"]

[mcp_servers."stellar-docs"]
command = "npx"
args = ["-y", "mcp-remote", "https://developers.stellar.org/mcp"]

[features]
foo = true
EOF
assert "detects quoted stellar-docs table" codex_mcp_has_table "$cfg" stellar-docs
assert "detects quoted other table" codex_mcp_has_table "$cfg" other
if codex_mcp_has_table "$cfg" stellar-raven; then
  assert "missing raven table is false" false
else
  assert "missing raven table is false" true
fi

echo "== TOML cleanup stays within target table (malformed args) =="
mal="$WORKDIR/malformed.toml"
cat > "$mal" <<'EOF'
keep_before = 1
[mcp_servers.stellar-docs]
command = "npx"
args = ["-y", "mcp-remote", "https://developers.stellar.org/mcp"
# intentionally unclosed / no terminating ] on args
extra = "inside-docs"
[mcp_servers.other]
command = "keep-me"
[misc]
value = 1
EOF
codex_mcp_remove_table "$mal" stellar-docs
assert_file_lacks "docs table header removed" "$mal" 'mcp_servers.stellar-docs'
assert_file_lacks "docs body removed" "$mal" 'inside-docs'
assert_file_has "unrelated MCP server preserved" "$mal" 'mcp_servers.other'
assert_file_has "trailing tables preserved" "$mal" 'value = 1'
assert_file_has "leading keys preserved" "$mal" 'keep_before = 1'

echo "== Quoted-table cleanup preserves neighbors =="
q="$WORKDIR/quoted.toml"
cat > "$q" <<'EOF'
[mcp_servers."stellar-docs"]
command = "npx"
args = ["-y", "mcp-remote", "https://developers.stellar.org/mcp"]
[mcp_servers.stellar-raven]
command = "npx"
args = ["-y", "mcp-remote", "https://raven.stellar.buzz/mcp"]
EOF
codex_mcp_remove_table "$q" stellar-docs
if codex_mcp_has_table "$q" stellar-docs; then
  assert "quoted docs gone" false
else
  assert "quoted docs gone" true
fi
assert "raven remains" codex_mcp_has_table "$q" stellar-raven

echo "== Multiline basic string with [ lines does not truncate remove =="
ml="$WORKDIR/multiline-basic.toml"
cat > "$ml" <<'EOF'
keep_before = true
[mcp_servers.stellar-docs]
command = "npx"
notes = """
line one
[looks-like-a-table]
line three
"""
args = ["-y", "mcp-remote", "https://developers.stellar.org/mcp"]
[mcp_servers.other]
command = "keep-me"
label = "after-docs"
[misc]
value = 1
EOF
codex_mcp_remove_table "$ml" stellar-docs
assert_file_lacks "multiline docs header removed" "$ml" 'mcp_servers.stellar-docs'
assert_file_lacks "multiline docs body removed" "$ml" 'looks-like-a-table'
assert_file_has "neighbor after multiline string preserved" "$ml" 'mcp_servers.other'
assert_file_has "neighbor command preserved" "$ml" 'keep-me'
assert_file_has "trailing misc preserved after multiline remove" "$ml" 'value = 1'
assert_file_has "leading key preserved after multiline remove" "$ml" 'keep_before = true'

echo "== Multiline literal string with [ lines does not truncate remove =="
mll="$WORKDIR/multiline-literal.toml"
cat > "$mll" <<'EOF'
[mcp_servers.stellar-docs]
command = "npx"
notes = '''
[also-not-a-header]
'''
args = ["-y", "mcp-remote", "https://developers.stellar.org/mcp"]
[mcp_servers.stellar-raven]
command = "npx"
EOF
codex_mcp_remove_table "$mll" stellar-docs
assert_file_lacks "literal-ml docs removed" "$mll" 'mcp_servers.stellar-docs'
assert_file_lacks "literal-ml fake header content removed" "$mll" 'also-not-a-header'
assert "raven survives literal multiline docs remove" codex_mcp_has_table "$mll" stellar-raven

echo "== Multiline args array with nested [ lines does not truncate remove =="
arr="$WORKDIR/multiline-array.toml"
cat > "$arr" <<'EOF'
[mcp_servers.stellar-docs]
command = "npx"
args = [
  "-y",
  "mcp-remote",
  [
    "https://developers.stellar.org/mcp"
  ],
  "[bracketed-arg]"
]
extra = "docs-only"
[mcp_servers.mirror]
command = "npx"
args = ["keep"]
EOF
codex_mcp_remove_table "$arr" stellar-docs
assert_file_lacks "array-form docs header removed" "$arr" 'mcp_servers.stellar-docs'
assert_file_lacks "array-form docs body removed" "$arr" 'docs-only'
assert_file_lacks "nested array content removed with docs" "$arr" 'bracketed-arg'
assert_file_has "mirror after nested-array docs preserved" "$arr" 'mcp_servers.mirror'
assert_file_has "mirror args preserved" "$arr" 'keep'

echo "== URL replace limited to one server table =="
u="$WORKDIR/urls.toml"
cat > "$u" <<'EOF'
[mcp_servers.stellar-raven]
command = "npx"
args = ["-y", "mcp-remote", "https://raven.stellar.buzz/mcp"]
[mcp_servers.mirror]
command = "npx"
args = ["-y", "mcp-remote", "https://raven.stellar.buzz/mcp"]
EOF
assert "replace succeeds on raven" codex_mcp_replace_url_in_table "$u" stellar-raven \
  "https://raven.stellar.buzz/mcp" "https://raven.stellar.org/mcp"
assert_file_has "raven URL updated" "$u" 'https://raven.stellar.org/mcp'
old_count="$(grep -cF 'https://raven.stellar.buzz/mcp' "$u" || true)"
assert_eq "other server URL untouched" "$old_count" "1"

echo "== URL replace across multiline array with [ lines preserves neighbors =="
um="$WORKDIR/urls-multiline.toml"
cat > "$um" <<'EOF'
[mcp_servers.stellar-raven]
command = "npx"
args = [
  "-y",
  "mcp-remote",
  "https://raven.stellar.buzz/mcp",
  [
    "extra"
  ]
]
notes = """
[do-not-cut-here]
"""
[mcp_servers.mirror]
command = "npx"
args = ["-y", "mcp-remote", "https://raven.stellar.buzz/mcp"]
EOF
assert "multiline replace succeeds" codex_mcp_replace_url_in_table "$um" stellar-raven \
  "https://raven.stellar.buzz/mcp" "https://raven.stellar.org/mcp"
assert "raven table still has new URL" codex_mcp_table_has_url "$um" stellar-raven \
  "https://raven.stellar.org/mcp"
if codex_mcp_table_has_url "$um" stellar-raven "https://raven.stellar.buzz/mcp"; then
  assert "raven table no longer has old URL" false
else
  assert "raven table no longer has old URL" true
fi
assert_file_has "multiline notes preserved after replace" "$um" 'do-not-cut-here'
assert_file_has "mirror old URL preserved after multiline replace" "$um" \
  'args = ["-y", "mcp-remote", "https://raven.stellar.buzz/mcp"]'
assert "mirror still reports old URL via helper" codex_mcp_table_has_url "$um" mirror \
  "https://raven.stellar.buzz/mcp"

echo "== Claude user-scope ownership detection =="
export HOME="$WORKDIR/home"
mkdir -p "$HOME"
# Re-bind MANIFEST_FILE for ownership tests against the sourced installer globals.
MANIFEST_FILE="$WORKDIR/manifest.json"
cat > "$HOME/.claude.json" <<'EOF'
{
  "mcpServers": {
    "stellar-docs": {
      "type": "http",
      "url": "https://developers.stellar.org/mcp"
    }
  },
  "projects": {
    "/tmp/proj": {
      "mcpServers": {
        "stellar-docs": {
          "type": "http",
          "url": "https://developers.stellar.org/mcp"
        }
      }
    }
  }
}
EOF
assert "user-scope stellar-docs detected" claude_user_mcp_has stellar-docs
if claude_user_mcp_has stellar-raven; then
  assert "absent user-scope raven not detected" false
else
  assert "absent user-scope raven not detected" true
fi

cat > "$HOME/.claude.json" <<'EOF'
{
  "projects": {
    "/tmp/proj": {
      "mcpServers": {
        "stellar-docs": {
          "type": "http",
          "url": "https://developers.stellar.org/mcp"
        }
      }
    }
  }
}
EOF
if claude_user_mcp_has stellar-docs; then
  assert "project-only docs does not count as user scope" false
else
  assert "project-only docs does not count as user scope" true
fi

echo "== Preserve custom Claude fields on URL migration =="
cat > "$HOME/.claude.json" <<'EOF'
{
  "mcpServers": {
    "stellar-raven": {
      "type": "http",
      "url": "https://raven.stellar.buzz/mcp",
      "alwaysLoad": true,
      "timeout": 60
    }
  }
}
EOF
backup="$(claude_user_mcp_get_json stellar-raven)"
assert "backup captured" bash -c '[ -n "$1" ]' _ "$backup"
claude_user_mcp_set_url stellar-raven "https://raven.stellar.org/mcp"
after="$(claude_user_mcp_get_json stellar-raven)"
assert_eq "alwaysLoad preserved" "$(node -e 'const o=JSON.parse(process.argv[1]); process.stdout.write(String(o.alwaysLoad===true))' "$after")" "true"
assert_eq "timeout preserved" "$(node -e 'const o=JSON.parse(process.argv[1]); process.stdout.write(String(o.timeout))' "$after")" "60"
assert_eq "url updated" "$(node -e 'const o=JSON.parse(process.argv[1]); process.stdout.write(o.url)' "$after")" "https://raven.stellar.org/mcp"

echo "== Rollback restores prior Claude entry =="
claude_user_mcp_set_entry stellar-raven "$backup"
restored="$(claude_user_mcp_get_json stellar-raven)"
assert_eq "rollback restored old URL" "$(node -e 'const o=JSON.parse(process.argv[1]); process.stdout.write(o.url)' "$restored")" "https://raven.stellar.buzz/mcp"
assert_eq "rollback restored alwaysLoad" "$(node -e 'const o=JSON.parse(process.argv[1]); process.stdout.write(String(o.alwaysLoad===true))' "$restored")" "true"

echo "== Manifest ownership via real manifest_flag_true helper =="
printf '{"docsMcpClaude":true,"docsMcpCodex":false,"ravenClaude":true}\n' > "$MANIFEST_FILE"
DOCS_MCP_CLAUDE=false
RAVEN_CLAUDE=false
manifest_flag_true docsMcpClaude && DOCS_MCP_CLAUDE=true
manifest_flag_true ravenClaude && RAVEN_CLAUDE=true
assert_eq "docsMcpClaude kept true via helper" "$DOCS_MCP_CLAUDE" "true"
assert_eq "ravenClaude kept true via helper" "$RAVEN_CLAUDE" "true"
if manifest_flag_true docsMcpCodex; then
  assert "docsMcpCodex false is not true" false
else
  assert "docsMcpCodex false is not true" true
fi
# Missing manifest must not claim ownership.
MANIFEST_FILE="$WORKDIR/missing-manifest.json"
if manifest_flag_true docsMcpClaude; then
  assert "missing manifest is not true" false
else
  assert "missing manifest is not true" true
fi
MANIFEST_FILE="$WORKDIR/manifest.json"

echo "== Codex migration failure reporting (no false success) =="
miss="$WORKDIR/miss-replace.toml"
cat > "$miss" <<'EOF'
[mcp_servers.stellar-raven]
command = "npx"
args = ["-y", "mcp-remote", "https://raven.stellar.org/mcp"]
[mcp_servers.mirror]
command = "npx"
args = ["-y", "mcp-remote", "https://raven.stellar.buzz/mcp"]
EOF
if codex_mcp_replace_url_in_table "$miss" stellar-raven \
    "https://raven.stellar.buzz/mcp" "https://raven.stellar.org/mcp"; then
  assert "replace fails when raven table already migrated" false
else
  assert "replace fails when raven table already migrated" true
fi
assert_file_has "mirror still on old URL after no-op" "$miss" 'https://raven.stellar.buzz/mcp'


echo "== README / bri / stellar-loop Raven guidance =="
if [ -f "$ROOT/README.md" ]; then
  assert "README has --scope user for Raven" \
    grep -q 'claude mcp add --transport http --scope user stellar-raven "https://raven.stellar.org/mcp"' \
    "$ROOT/README.md"
fi
if [ -f "$ROOT/skills/methodology/bri-tech-writer/SKILL.md" ]; then
  assert "bri skill mentions Codex config.toml" \
    grep -q 'mcp_servers.stellar-raven' "$ROOT/skills/methodology/bri-tech-writer/SKILL.md"
  assert "bri skill mentions stellar-loop raven login codex" \
    grep -q 'stellar-loop raven login codex' "$ROOT/skills/methodology/bri-tech-writer/SKILL.md"
fi
if [ -f "$ROOT/skills/loop/bin/stellar-loop" ]; then
  assert "stellar-loop defines raven_codex_authenticated" \
    grep -q '^raven_codex_authenticated()' "$ROOT/skills/loop/bin/stellar-loop"
  assert "login waits on raven_codex_authenticated" \
    grep -q 'raven_codex_authenticated && break' "$ROOT/skills/loop/bin/stellar-loop"
fi
if grep -q 'codex_mcp_replace_url_in_table "$CODEX_CONFIG" stellar-raven' "$ROOT/install.sh"; then
  if grep -A6 'codex_mcp_replace_url_in_table "$CODEX_CONFIG" stellar-raven' "$ROOT/install.sh" \
      | grep -q 'ok "Raven MCP moved to raven.stellar.org for Codex"'; then
    assert "install only ok's Codex move after successful replace" true
  else
    assert "install only ok's Codex move after successful replace" false
  fi
  assert "install warns when Codex migrate fails" \
    grep -q 'Could not migrate Raven URL in Codex config.toml' "$ROOT/install.sh"
  assert "install rolls back Claude entry on migrate failure" \
    grep -q 'claude_user_mcp_set_entry stellar-raven "$RAVEN_BACKUP"' "$ROOT/install.sh"
fi

echo "== install.sh / stellar-loop syntax =="
assert "bash -n install.sh" bash -n "$ROOT/install.sh"
if [ -f "$ROOT/skills/loop/bin/stellar-loop" ]; then
  assert "bash -n stellar-loop" bash -n "$ROOT/skills/loop/bin/stellar-loop"
fi

echo
printf 'Results: %s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
