#!/usr/bin/env bash
# Regression coverage for installer MCP helpers and ownership/scope behavior.
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

# Confirm install.sh still defines the same helper entrypoints the tests cover.
for fn in codex_mcp_table_re codex_mcp_has_table codex_mcp_remove_table \
          codex_mcp_replace_url_in_table claude_json_path claude_user_mcp_has; do
  assert "install.sh defines $fn" grep -q "^${fn}()" "$ROOT/install.sh"
done

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
# Exactly one old URL should remain (the mirror server).
old_count="$(grep -cF 'https://raven.stellar.buzz/mcp' "$u" || true)"
assert_eq "other server URL untouched" "$old_count" "1"

echo "== Claude user-scope ownership detection =="
export HOME="$WORKDIR/home"
mkdir -p "$HOME"
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

# Project-only registration lives under projects.*, not top-level mcpServers.
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
assert "backup captured" bash -c '[ -n "$0" ]' "$backup"
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

echo "== Manifest ownership flag preserved when Claude absent (docs) =="
# Simulate the installer flag restore line without requiring a full install.
MANIFEST="$WORKDIR/manifest.json"
printf '{"docsMcpClaude":true,"docsMcpCodex":false}\n' > "$MANIFEST"
DOCS_MCP_CLAUDE=false
grep -q '"docsMcpClaude":true' "$MANIFEST" 2>/dev/null && DOCS_MCP_CLAUDE=true
assert_eq "docsMcpClaude kept true without claude CLI" "$DOCS_MCP_CLAUDE" "true"

echo "== install.sh syntax =="
assert "bash -n install.sh" bash -n "$ROOT/install.sh"

echo
printf 'Results: %s passed, %s failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
