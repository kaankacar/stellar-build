#!/usr/bin/env bash
# Shared MCP helper copies for unit tests. Kept aligned with install.sh helpers.
set -euo pipefail

codex_mcp_table_re() {
  printf '\\[mcp_servers\\.("%s"|%s)\\]' "$1" "$1"
}

codex_mcp_has_table() {
  [ -f "$1" ] || return 1
  grep -Eq "$(codex_mcp_table_re "$2")" "$1"
}

codex_mcp_remove_table() {
  local f="$1" name="$2" re tmp
  [ -f "$f" ] || return 0
  re="$(codex_mcp_table_re "$name")"
  tmp="$(mktemp)"
  awk -v re="^${re}$" '
    $0 ~ re { skip=1; next }
    skip && /^\[/ { skip=0 }
    !skip { print }
  ' "$f" > "$tmp" && mv "$tmp" "$f" || { rm -f "$tmp"; return 1; }
}

codex_mcp_replace_url_in_table() {
  local f="$1" name="$2" old="$3" new="$4" re tmp
  [ -f "$f" ] || return 1
  re="$(codex_mcp_table_re "$name")"
  tmp="$(mktemp)"
  awk -v re="^${re}$" -v old="$old" -v new="$new" '
    $0 ~ re { in_tbl=1; print; next }
    in_tbl && /^\[/ { in_tbl=0 }
    in_tbl { idx = index($0, old); if (idx) { $0 = substr($0, 1, idx-1) new substr($0, idx+length(old)); replaced=1 } }
    { print }
    END { exit replaced ? 0 : 1 }
  ' "$f" > "$tmp"
  local rc=$?
  if [ "$rc" -eq 0 ]; then
    mv "$tmp" "$f"
  else
    rm -f "$tmp"
  fi
  return "$rc"
}

codex_mcp_table_has_url() {
  local f="$1" name="$2" url="$3" re
  [ -f "$f" ] || return 1
  re="$(codex_mcp_table_re "$name")"
  awk -v re="^${re}$" -v url="$url" '
    $0 ~ re { in_tbl=1; next }
    in_tbl && /^\[/ { in_tbl=0 }
    in_tbl && index($0, url) { found=1; exit }
    END { exit found ? 0 : 1 }
  ' "$f"
}

claude_json_path() {
  if [ -n "${CLAUDE_CONFIG_DIR:-}" ]; then
    printf '%s/.claude.json\n' "$CLAUDE_CONFIG_DIR"
  else
    printf '%s/.claude.json\n' "$HOME"
  fi
}

claude_user_mcp_has() {
  local f name="$1"
  f="$(claude_json_path)"
  [ -f "$f" ] || return 1
  command -v node >/dev/null 2>&1 || return 1
  node -e '
    const fs = require("fs");
    const [file, name] = process.argv.slice(1);
    let c = {};
    try { c = JSON.parse(fs.readFileSync(file, "utf8") || "{}"); } catch (e) { process.exit(1); }
    process.exit(c.mcpServers && c.mcpServers[name] ? 0 : 1);
  ' "$f" "$name"
}

claude_user_mcp_get_json() {
  local f name="$1"
  f="$(claude_json_path)"
  [ -f "$f" ] || return 1
  command -v node >/dev/null 2>&1 || return 1
  node -e '
    const fs = require("fs");
    const [file, name] = process.argv.slice(1);
    let c = {};
    try { c = JSON.parse(fs.readFileSync(file, "utf8") || "{}"); } catch (e) { process.exit(1); }
    if (!c.mcpServers || !c.mcpServers[name]) process.exit(1);
    process.stdout.write(JSON.stringify(c.mcpServers[name]));
  ' "$f" "$name"
}

claude_user_mcp_url() {
  local f name="$1"
  f="$(claude_json_path)"
  [ -f "$f" ] || return 1
  command -v node >/dev/null 2>&1 || return 1
  node -e '
    const fs = require("fs");
    const [file, name] = process.argv.slice(1);
    let c = {};
    try { c = JSON.parse(fs.readFileSync(file, "utf8") || "{}"); } catch (e) { process.exit(1); }
    if (!c.mcpServers || !c.mcpServers[name]) process.exit(1);
    process.stdout.write(c.mcpServers[name].url || "");
  ' "$f" "$name"
}

claude_user_mcp_set_entry() {
  local name="$1" json="$2" f
  f="$(claude_json_path)"
  command -v node >/dev/null 2>&1 || return 1
  mkdir -p "$(dirname "$f")"
  [ -f "$f" ] || printf '{}\n' > "$f"
  node -e '
    const fs = require("fs");
    const [file, name, raw] = process.argv.slice(1);
    let c = {};
    try { c = JSON.parse(fs.readFileSync(file, "utf8") || "{}"); } catch (e) { c = {}; }
    if (!c.mcpServers || typeof c.mcpServers !== "object") c.mcpServers = {};
    c.mcpServers[name] = JSON.parse(raw);
    const tmp = file + ".tmp";
    fs.writeFileSync(tmp, JSON.stringify(c, null, 2) + "\n");
    fs.renameSync(tmp, file);
  ' "$f" "$name" "$json"
}

claude_user_mcp_set_url() {
  local name="$1" url="$2" f
  f="$(claude_json_path)"
  [ -f "$f" ] || return 1
  command -v node >/dev/null 2>&1 || return 1
  node -e '
    const fs = require("fs");
    const [file, name, url] = process.argv.slice(1);
    let c = {};
    try { c = JSON.parse(fs.readFileSync(file, "utf8") || "{}"); } catch (e) { process.exit(1); }
    if (!c.mcpServers || !c.mcpServers[name]) process.exit(1);
    const prev = JSON.stringify(c.mcpServers[name]);
    c.mcpServers[name] = { ...c.mcpServers[name], url };
    const tmp = file + ".tmp";
    try {
      fs.writeFileSync(tmp, JSON.stringify(c, null, 2) + "\n");
      fs.renameSync(tmp, file);
    } catch (e) {
      try { fs.unlinkSync(tmp); } catch (_) {}
      process.exit(1);
    }
    if (JSON.stringify(c.mcpServers[name]) === prev) process.exit(1);
  ' "$f" "$name" "$url"
}
