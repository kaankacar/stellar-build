#!/usr/bin/env bash
# stellar-build — Stellar development journey installer (modeled on solana.new/setup.sh)
#
# Usage:
#   Hosted:   curl -fsSL https://your-domain/install.sh | bash
#   Local:    LOCAL_BUNDLE=./bundle.tar.gz ./install.sh
#   Sandbox:  ./install.sh --prefix=/tmp/sandbox
#   Update:   ./install.sh --update
#   Remove:   ./install.sh --uninstall

set -euo pipefail

PRODUCT_NAME="stellar-build"

# Multi-source: each source ships skills from a different upstream.
# Override URLs via env var; override with a local path via LOCAL_* for testing.
SOURCE_OUR_BUNDLE_URL="${BUNDLE_URL:-https://raw.githubusercontent.com/kaankacar/stellar-build/main/bundle.tar.gz}"
SOURCE_SCF_URL="${SCF_URL:-https://github.com/lumenloop/awesome-stellar-community-fund/archive/refs/heads/main.tar.gz}"
SOURCE_STELLAR_DEV_URL="${STELLAR_DEV_URL:-https://github.com/stellar/stellar-dev-skill/archive/refs/heads/main.tar.gz}"

LOCAL_BUNDLE="${LOCAL_BUNDLE:-}"          # file path to our bundle.tar.gz
LOCAL_SCF="${LOCAL_SCF:-}"                # file or dir for awesome-stellar-community-fund
LOCAL_STELLAR_DEV="${LOCAL_STELLAR_DEV:-}" # file or dir for stellar-dev-skill

# --- Colors ---
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
CYAN=$'\033[0;36m'
BOLD=$'\033[1m'
DIM=$'\033[2m'
RESET=$'\033[0m'

log()  { printf "\n  %s▸%s %s\n" "$GREEN" "$RESET" "$1"; }
warn() { printf "  %s!%s %s\n" "$YELLOW" "$RESET" "$1"; }
fail() { printf "\n  %s✗%s %s\n\n" "$RED" "$RESET" "$1" >&2; exit 1; }
ok()   { printf "  %s✓%s %s\n" "$GREEN" "$RESET" "$1"; }
has_cmd() { command -v "$1" >/dev/null 2>&1; }

# --- Parse flags ---
UPDATE_MODE=false
UNINSTALL_MODE=false
PREFIX="$HOME"
for arg in "$@"; do
  case "$arg" in
    --update)     UPDATE_MODE=true ;;
    --uninstall)  UNINSTALL_MODE=true ;;
    --prefix=*)   PREFIX="${arg#--prefix=}" ;;
  esac
done

CLAUDE_SKILLS="$PREFIX/.claude/skills"
CODEX_SKILLS="$PREFIX/.codex/skills"
CONFIG_DIR="$PREFIX/.${PRODUCT_NAME}"
# Pre-July-2026 installs used ~/.stellar — which collides with the Stellar
# CLI's (deprecated) global config dir and made the CLI print deprecation
# notices. We migrate our files out and never touch anything else in there.
LEGACY_CONFIG_DIR="$PREFIX/.stellar"
MANIFEST_FILE="$CONFIG_DIR/manifest.json"
CLAUDE_SETTINGS="$PREFIX/.claude/settings.json"

# Everything stellar-build ever writes into its config dir. Used to migrate
# out of (and safely clean up) the legacy ~/.stellar without touching files
# owned by the Stellar CLI.
OWNED_CONFIG_ITEMS="manifest.json traces backups bench hooks bin cache .active .prompts profile.md optimizations.jsonl state.json .codex_ingested config.yaml templates"

# --- Manifest helpers ---
read_manifest_array() {
  [ -f "$MANIFEST_FILE" ] || return 1
  sed -n "s/.*\"$1\":\[\([^]]*\)\].*/\1/p" "$MANIFEST_FILE" 2>/dev/null \
    | grep -o '"[^"]*"' | tr -d '"'
}

# Strip every learning-loop hook (trace / prompt-capture / session-start) that
# points into a given hooks dir, from a Claude settings.json or Codex
# hooks.json. Shared by uninstall and the legacy-dir migration.
clean_hooks_by_marker() {  # $1 = json file, $2 = hooks-dir marker
  local f="$1" marker="$2"
  [ -f "$f" ] || return 0
  has_cmd node || return 1
  node -e '
    const fs = require("fs");
    const [file, marker] = process.argv.slice(1);
    const c = JSON.parse(fs.readFileSync(file, "utf8") || "{}");
    if (c.hooks && typeof c.hooks === "object") {
      for (const ev of Object.keys(c.hooks)) {
        if (!Array.isArray(c.hooks[ev])) continue;
        c.hooks[ev] = c.hooks[ev]
          .map(g => (g && Array.isArray(g.hooks))
            ? { ...g, hooks: g.hooks.filter(h => !(h && typeof h.command === "string" && h.command.includes(marker))) }
            : g)
          .filter(g => !(g && Array.isArray(g.hooks) && g.hooks.length === 0));
        if (c.hooks[ev].length === 0) delete c.hooks[ev];
      }
      if (Object.keys(c.hooks).length === 0) delete c.hooks;
    }
    fs.writeFileSync(file, JSON.stringify(c, null, 2));
  ' "$f" "$marker" 2>/dev/null
}

# Remove only stellar-build-owned items from a config dir, then remove the dir
# itself only if nothing else remains (the legacy ~/.stellar may hold Stellar
# CLI files — those must survive).
remove_owned_config() {  # $1 = config dir
  local dir="$1" item
  [ -d "$dir" ] || return 0
  for item in $OWNED_CONFIG_ITEMS; do
    rm -rf "${dir:?}/$item" 2>/dev/null || true
  done
  rmdir "$dir" 2>/dev/null || true
}

# --- Uninstall mode ---
if [ "$UNINSTALL_MODE" = true ]; then
  printf "\n  %s%sUninstalling %s...%s\n\n" "$CYAN" "$BOLD" "$PRODUCT_NAME" "$RESET"
  # Fall back to the legacy ~/.stellar location for installs that predate the
  # ~/.stellar-build rename and were never updated.
  if [ ! -f "$MANIFEST_FILE" ] && [ -f "$LEGACY_CONFIG_DIR/manifest.json" ]; then
    CONFIG_DIR="$LEGACY_CONFIG_DIR"
    MANIFEST_FILE="$CONFIG_DIR/manifest.json"
    warn "Using legacy config at $CONFIG_DIR"
  fi
  if [ ! -f "$MANIFEST_FILE" ]; then
    warn "No manifest found at $MANIFEST_FILE — nothing to uninstall"
    exit 0
  fi

  REMOVED=0
  while IFS= read -r skill_path; do
    [ -z "$skill_path" ] && continue
    if [ -d "$skill_path" ]; then
      rm -rf "$skill_path"
      REMOVED=$((REMOVED + 1))
    elif [ -f "$skill_path" ]; then
      rm -f "$skill_path"
      REMOVED=$((REMOVED + 1))
    fi
  done <<EOF
$(read_manifest_array skillPaths)
EOF

  while IFS= read -r shared_path; do
    [ -z "$shared_path" ] && continue
    [ -e "$shared_path" ] && rm -rf "$shared_path"
  done <<EOF
$(read_manifest_array sharedPaths)
EOF

  # Revert Claude Code permissions.
  # NB: trailing `|| true` is required — read_manifest_array's internal grep
  # exits non-zero when permissionsAdded is empty (e.g. after an --update,
  # which records []), and under `set -o pipefail` that would otherwise abort
  # the entire uninstall before the hook + config cleanup below ever runs.
  PERMS_TO_REMOVE=$(read_manifest_array permissionsAdded | tr '\n' ',' | sed 's/,$//' || true)
  if [ -n "$PERMS_TO_REMOVE" ] && [ -f "$CLAUDE_SETTINGS" ] && has_cmd node; then
    node -e "
      const fs = require('fs');
      const c = JSON.parse(fs.readFileSync('$CLAUDE_SETTINGS', 'utf8'));
      const toRemove = '$PERMS_TO_REMOVE'.split(',');
      if (c.permissions && Array.isArray(c.permissions.allow)) {
        c.permissions.allow = c.permissions.allow.filter(r => !toRemove.includes(r));
        if (c.permissions.allow.length === 0) delete c.permissions.allow;
        if (Object.keys(c.permissions).length === 0) delete c.permissions;
      }
      fs.writeFileSync('$CLAUDE_SETTINGS', JSON.stringify(c, null, 2));
    " 2>/dev/null && ok "Reverted Claude Code permissions" || warn "Could not revert Claude settings"
  fi

  # Remove the learning-loop hooks from Claude settings and Codex hooks.json.
  # We match by hooks-dir marker (both the current and the legacy location),
  # so all events are cleaned regardless of how they're nested.
  if has_cmd node; then
    { clean_hooks_by_marker "$CLAUDE_SETTINGS" "$CONFIG_DIR/hooks/" \
        && clean_hooks_by_marker "$CLAUDE_SETTINGS" "$LEGACY_CONFIG_DIR/hooks/"; } \
      && ok "Removed learning-loop hooks from Claude settings" \
      || warn "Could not clean Claude hooks"
    clean_hooks_by_marker "$PREFIX/.codex/hooks.json" "$CONFIG_DIR/hooks/" \
      && clean_hooks_by_marker "$PREFIX/.codex/hooks.json" "$LEGACY_CONFIG_DIR/hooks/" \
      && ok "Removed learning-loop hooks from Codex"
  fi

  # Disconnect the Raven MCP server if this install added it.
  if grep -q '"ravenClaude":true' "$MANIFEST_FILE" 2>/dev/null && has_cmd claude; then
    claude mcp remove --scope user stellar-raven >/dev/null 2>&1 \
      && ok "Disconnected Raven MCP from Claude Code" || true
  fi
  if grep -q '"ravenCodex":true' "$MANIFEST_FILE" 2>/dev/null && [ -f "$PREFIX/.codex/config.toml" ]; then
    sed -i.bak '/^\[mcp_servers\.stellar-raven\]$/,/^args = .*mcp-remote.*\]$/d' "$PREFIX/.codex/config.toml" 2>/dev/null \
      && rm -f "$PREFIX/.codex/config.toml.bak" \
      && ok "Disconnected Raven MCP from Codex" || true
  fi

  # Never `rm -rf` the legacy ~/.stellar — the Stellar CLI may keep its own
  # config there. Remove only what we own; the dir goes away only if empty.
  remove_owned_config "$CONFIG_DIR"
  ok "Removed $REMOVED skills and config"
  printf "\n  %sTo reinstall: ./install.sh%s\n\n" "$DIM" "$RESET"
  exit 0
fi

# --- Banner ---
printf "\n"
printf "  %sstellar-build%s  %s· installing...%s\n" "$BOLD" "$RESET" "$DIM" "$RESET"
if [ "$UPDATE_MODE" = true ]; then
  printf "  %sUpdating skills...%s\n\n" "$DIM" "$RESET"
else
  printf "  %sYour Stellar dev journey — idea to mainnet.%s\n\n" "$DIM" "$RESET"
fi

# --- Prereqs ---
log "Checking prerequisites..."
if ! has_cmd curl && ! has_cmd wget; then
  fail "curl or wget is required"
fi
if has_cmd claude; then ok "Claude Code found"
else warn "Claude Code not found (install: npm i -g @anthropic-ai/claude-code)"
fi

# --- Acquire sources ---
TMP_DIR=$(mktemp -d)
cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

# acquire_source <name> <url> <local_override>
# Local override can be a tarball OR a directory (already extracted).
# Returns 0 on success, non-zero on failure (caller decides whether to fail).
acquire_source() {
  local name="$1" url="$2" local_override="$3"
  local dest="$TMP_DIR/$name"
  mkdir -p "$dest"

  if [ -n "$local_override" ]; then
    if [ -d "$local_override" ]; then
      log "Using local $name from $local_override"
      cp -R "$local_override/." "$dest/"
      return 0
    elif [ -f "$local_override" ]; then
      log "Using local $name tarball: $local_override"
      tar -xzf "$local_override" -C "$dest" || return 1
      return 0
    else
      warn "LOCAL_$name path doesn't exist: $local_override"
      return 1
    fi
  fi

  log "Downloading $name from $url"
  if has_cmd curl; then
    curl -fsSL "$url" -o "$dest/source.tar.gz" || return 1
  else
    wget -q "$url" -O "$dest/source.tar.gz" || return 1
  fi
  tar -xzf "$dest/source.tar.gz" -C "$dest" || return 1
  return 0
}

# Fetch all three sources. Our bundle is required; SCF + stellar-dev are best-effort.
acquire_source "our-bundle" "$SOURCE_OUR_BUNDLE_URL" "$LOCAL_BUNDLE" \
  || fail "Failed to fetch our bundle (required)"
ok "our-bundle ready"

SCF_AVAILABLE=true
acquire_source "scf" "$SOURCE_SCF_URL" "$LOCAL_SCF" \
  || { warn "Failed to fetch SCF skills — installation will skip SCF"; SCF_AVAILABLE=false; }
$SCF_AVAILABLE && ok "scf ready"

STELLAR_DEV_AVAILABLE=true
acquire_source "stellar-dev" "$SOURCE_STELLAR_DEV_URL" "$LOCAL_STELLAR_DEV" \
  || { warn "Failed to fetch Stellar dev skills — installation will skip them"; STELLAR_DEV_AVAILABLE=false; }
$STELLAR_DEV_AVAILABLE && ok "stellar-dev ready"

# --- Install ---
log "Installing to $PREFIX..."

# Migrate pre-July-2026 installs out of the legacy ~/.stellar dir (it collides
# with the Stellar CLI's deprecated global config dir). Move only files we own,
# leave everything else — and the dir itself, unless empty — untouched.
if [ -f "$LEGACY_CONFIG_DIR/manifest.json" ] && [ ! -f "$MANIFEST_FILE" ]; then
  log "Migrating config from $LEGACY_CONFIG_DIR to $CONFIG_DIR..."
  mkdir -p "$CONFIG_DIR"
  for item in $OWNED_CONFIG_ITEMS; do
    [ -e "$LEGACY_CONFIG_DIR/$item" ] && mv "$LEGACY_CONFIG_DIR/$item" "$CONFIG_DIR/" 2>/dev/null || true
  done
  if rmdir "$LEGACY_CONFIG_DIR" 2>/dev/null; then
    ok "Migrated and removed $LEGACY_CONFIG_DIR"
  else
    ok "Migrated stellar-build files ($LEGACY_CONFIG_DIR kept — it holds other files, likely Stellar CLI config)"
  fi
  # Old hook registrations point at the legacy path; strip them here — the
  # hook-registration step below re-adds them at the new location.
  clean_hooks_by_marker "$CLAUDE_SETTINGS" "$LEGACY_CONFIG_DIR/hooks/" || true
  clean_hooks_by_marker "$PREFIX/.codex/hooks.json" "$LEGACY_CONFIG_DIR/hooks/" || true
fi

mkdir -p "$CLAUDE_SKILLS" "$CODEX_SKILLS" "$CONFIG_DIR"

FOLDER_SKILLS=""  # names of folder-based installed skills
FLAT_SKILLS=""    # basenames (no .md) of flat-md installed skills

install_folder_skill() {
  local skill_dir="$1"
  local skill_name
  skill_name=$(basename "$skill_dir")
  cp -Rf "$skill_dir" "$CLAUDE_SKILLS/$skill_name"
  cp -Rf "$skill_dir" "$CODEX_SKILLS/$skill_name"
  FOLDER_SKILLS="${FOLDER_SKILLS}${skill_name} "
}

install_flat_skill() {
  local md_file="$1"
  local base
  base=$(basename "$md_file" .md)
  [ "$base" = "README" ] && return 0
  cp -f "$md_file" "$CLAUDE_SKILLS/${base}.md"
  cp -f "$md_file" "$CODEX_SKILLS/${base}.md"
  FLAT_SKILLS="${FLAT_SKILLS}${base} "
}

# 1. Our bundle — folder-based skills in skills/methodology/* and skills/stellar/*,
#    plus SKILL_ROUTER.md and shared data/
OUR_SRC="$TMP_DIR/our-bundle"
if [ -d "$OUR_SRC/skills" ]; then
  for skill_dir in "$OUR_SRC/skills"/*/*/; do
    [ -d "$skill_dir" ] || continue
    [ -f "$skill_dir/SKILL.md" ] || continue
    install_folder_skill "$skill_dir"
  done
  [ -f "$OUR_SRC/skills/SKILL_ROUTER.md" ] && {
    cp -f "$OUR_SRC/skills/SKILL_ROUTER.md" "$CLAUDE_SKILLS/"
    cp -f "$OUR_SRC/skills/SKILL_ROUTER.md" "$CODEX_SKILLS/"
  }
  if [ -d "$OUR_SRC/skills/data" ]; then
    mkdir -p "$CLAUDE_SKILLS/data" "$CODEX_SKILLS/data"
    cp -Rf "$OUR_SRC/skills/data/"* "$CLAUDE_SKILLS/data/" 2>/dev/null || true
    cp -Rf "$OUR_SRC/skills/data/"* "$CODEX_SKILLS/data/" 2>/dev/null || true
  fi

  # Learning loop — the trace hook and CLI live outside the skills dir, under
  # the config dir (~/.stellar-build). The skill folders themselves (learning-loop,
  # optimize-skills, bench-skills) install via the folder-skill loop above.
  mkdir -p "$CONFIG_DIR/traces" "$CONFIG_DIR/backups" "$CONFIG_DIR/bench" "$CONFIG_DIR/hooks" "$CONFIG_DIR/bin" "$CONFIG_DIR/.active" "$CONFIG_DIR/.prompts"
  if [ -d "$OUR_SRC/skills/loop/hooks" ]; then
    cp -f "$OUR_SRC/skills/loop/hooks/"* "$CONFIG_DIR/hooks/" 2>/dev/null || true
    chmod +x "$CONFIG_DIR/hooks/"*.sh 2>/dev/null || true
  fi
  if [ -d "$OUR_SRC/skills/loop/bin" ]; then
    cp -f "$OUR_SRC/skills/loop/bin/"* "$CONFIG_DIR/bin/" 2>/dev/null || true
    chmod +x "$CONFIG_DIR/bin/"* 2>/dev/null || true
  fi

  # Global persona/workflow config — user-scoped defaults skills can read from
  # any project, so a fresh folder needs zero per-project setup. Written once;
  # never overwritten on update, so user edits survive. Project-level overrides
  # live in {project}/.stellar-build/bmm/config.yaml (optional).
  if [ ! -f "$CONFIG_DIR/config.yaml" ]; then
    # Escape backslashes and double quotes so the name is always valid YAML;
    # keep only the first line in case of a pathological multi-line value.
    GIT_USER_NAME="$(git config --get user.name 2>/dev/null | head -n1 | sed 's/\\/\\\\/g; s/"/\\"/g' || true)"
    {
      cat <<'CFGEOF'
# stellar-build global config. Skills read these values in any project that
# has no .stellar-build/bmm/config.yaml of its own. Edit freely — updates
# never overwrite this file.
CFGEOF
      if [ -n "$GIT_USER_NAME" ]; then
        printf 'user_name: "%s"\n' "$GIT_USER_NAME"
      fi
      cat <<'CFGEOF'
communication_language: English
document_output_language: English
user_skill_level: intermediate
CFGEOF
    } > "$CONFIG_DIR/config.yaml"
    ok "Wrote global config ($CONFIG_DIR/config.yaml)"
  fi

  # Project-config template — personas copy this into a project when the user
  # asks to "set up project config". Installer-owned: refreshed on update.
  mkdir -p "$CONFIG_DIR/templates"
  cat > "$CONFIG_DIR/templates/project-config.yaml" <<TPLEOF
# stellar-build project config. Copy to {project}/.stellar-build/bmm/config.yaml
# (any persona will do this for you if you ask to "set up project config").
# Every key is optional — anything missing falls back to this install's global
# config at ${CONFIG_DIR}/config.yaml, then to built-in defaults. Paths
# resolve relative to the project root.

# project_name: my-project
# planning_artifacts: docs                # PRDs, briefs, architecture, epics
# implementation_artifacts: docs/stories  # stories, sprint-status.yaml
# project_knowledge: docs                 # extra context skills may scan
# user_name: Your Name                    # per-project override of the global value
# communication_language: English
# document_output_language: English
# user_skill_level: intermediate
TPLEOF
fi

# 2. SCF — upstream moved from flat .md files to folder-based skills
#    (<skill>/SKILL.md); handle both layouts. GitHub tarballs extract with a
#    "<repo>-<branch>" top dir.
if $SCF_AVAILABLE; then
  SCF_SKILLS_DIR=$(find "$TMP_DIR/scf" -mindepth 1 -maxdepth 2 -type d -name "skills" | head -1)
  if [ -n "$SCF_SKILLS_DIR" ] && [ -d "$SCF_SKILLS_DIR" ]; then
    for skill_dir in "$SCF_SKILLS_DIR"/*/; do
      [ -d "$skill_dir" ] || continue
      [ -f "$skill_dir/SKILL.md" ] || continue
      install_folder_skill "$skill_dir"
    done
    for md_file in "$SCF_SKILLS_DIR"/*.md; do
      [ -f "$md_file" ] || continue
      install_flat_skill "$md_file"
    done
  else
    warn "SCF skills/ dir not found inside extracted archive"
  fi
fi

# 3. Stellar dev — folder-based skills in skills/<name>/SKILL.md
if $STELLAR_DEV_AVAILABLE; then
  DEV_SKILLS_DIR=$(find "$TMP_DIR/stellar-dev" -mindepth 1 -maxdepth 2 -type d -name "skills" | head -1)
  if [ -n "$DEV_SKILLS_DIR" ] && [ -d "$DEV_SKILLS_DIR" ]; then
    for skill_dir in "$DEV_SKILLS_DIR"/*/; do
      [ -d "$skill_dir" ] || continue
      [ -f "$skill_dir/SKILL.md" ] || continue
      install_folder_skill "$skill_dir"
    done
  else
    warn "Stellar dev skills/ dir not found inside extracted archive"
  fi
fi

# Count: folder skills (with SKILL.md, max depth 2) + flat .md skills at depth 1
# (exclude SKILL_ROUTER.md, README.md, NOTICES.md, LINKS.md)
folder_count=$(find "$CLAUDE_SKILLS" -maxdepth 2 -name SKILL.md 2>/dev/null | wc -l | tr -d ' ')
flat_count=$(find "$CLAUDE_SKILLS" -maxdepth 1 -name "*.md" -not -name "SKILL_ROUTER.md" -not -name "README.md" -not -name "NOTICES.md" -not -name "LINKS.md" 2>/dev/null | wc -l | tr -d ' ')
SKILL_COUNT=$((folder_count + flat_count))
ok "Installed $SKILL_COUNT skills to .claude/skills/ ($folder_count folder + $flat_count flat)"
ok "Installed $SKILL_COUNT skills to .codex/skills/"

# --- Permissions ---
log "Configuring Claude Code permissions..."
PERMS_ADDED=""
if [ -f "$CLAUDE_SETTINGS" ] && has_cmd node; then
  PERMS_ADDED=$(node -e "
    const fs = require('fs');
    const c = JSON.parse(fs.readFileSync('$CLAUDE_SETTINGS', 'utf8'));
    if (!c.permissions) c.permissions = {};
    if (!c.permissions.allow) c.permissions.allow = [];
    const want = ['Bash', 'Read', 'Glob', 'Grep'];
    const added = [];
    for (const r of want) {
      if (!c.permissions.allow.includes(r)) { c.permissions.allow.push(r); added.push(r); }
    }
    fs.writeFileSync('$CLAUDE_SETTINGS', JSON.stringify(c, null, 2));
    console.log(added.join(','));
  " 2>/dev/null) && ok "Auto-allow skill preambles: enabled" || warn "Could not update Claude settings"
elif [ ! -f "$CLAUDE_SETTINGS" ]; then
  mkdir -p "$(dirname "$CLAUDE_SETTINGS")"
  printf '{\n  "permissions": {\n    "allow": ["Bash", "Read", "Glob", "Grep"]\n  }\n}\n' > "$CLAUDE_SETTINGS"
  PERMS_ADDED="Bash,Read,Glob,Grep"
  ok "Created $CLAUDE_SETTINGS"
fi

# --- Learning loop: register hooks (Claude Code + Codex) ---
# These hooks make the loop automatic and high-signal. A skill use is a
# multi-turn span, so capture is decoupled from "skill became active":
#   PostToolUse       -> trace-skill.sh        (open/rotate the active-skill pointer)
#   Stop              -> stop-trace.sh         (Claude only: one real record per turn)
#   SessionEnd        -> session-end.sh        (Claude only: close the span, bump once)
#   UserPromptSubmit  -> capture-prompt.sh     (stash the prompt for pairing)
#   UserPromptSubmit  -> reprompt.sh           (per-turn prompt sharpener)
#   SessionStart      -> loop-session-start.sh (self-trigger: nudge / auto-optimize)
# Codex has no Stop/SessionEnd + transcript pipeline, so trace-skill.sh keeps
# writing a synchronous record there (backfilled by `stellar-loop ingest-codex`).
# Claude Code reads ~/.claude/settings.json; Codex reads ~/.codex/hooks.json —
# both share the same hook schema, so one merge routine serves both. Idempotent:
# re-running install (or --update) never adds duplicates.
HOOKS_DIR="$CONFIG_DIR/hooks"
HOOK_CMD="$HOOKS_DIR/trace-skill.sh"   # recorded in the manifest as the loop marker
CODEX_HOOKS="$PREFIX/.codex/hooks.json"

register_loop_hooks() {  # $1 = target json file, $2 = agent (claude|codex)
  local target="$1" agent="$2"
  [ -f "$target" ] || { mkdir -p "$(dirname "$target")"; printf '{}\n' > "$target"; }
  node -e '
    const fs = require("fs");
    const [file, hooksDir, agent] = process.argv.slice(1);
    const c = JSON.parse(fs.readFileSync(file, "utf8") || "{}");
    c.hooks = c.hooks || {};
    // Codex fires PostToolUse for every tool call (its skill tool name is not
    // guaranteed), so match all and let the wrapper self-filter to skills.
    // Claude Code scopes the matcher to the Skill tool directly.
    const traceCmd = agent === "codex"
      ? `STELLAR_TRACE_AGENT=codex ${hooksDir}/trace-skill.sh`
      : `${hooksDir}/trace-skill.sh`;
    const specs = [
      { event: "PostToolUse",      matcher: agent === "codex" ? ".*" : "Skill", cmd: traceCmd },
      { event: "UserPromptSubmit", matcher: "",                                 cmd: `${hooksDir}/capture-prompt.sh` },
      { event: "UserPromptSubmit", matcher: "",                                 cmd: `${hooksDir}/reprompt.sh` },
      { event: "SessionStart",     matcher: "",                                 cmd: `${hooksDir}/loop-session-start.sh` },
    ];
    // A skill use is a multi-turn span, but the Skill tool fires once per mount.
    // On Claude Code the real per-turn output is captured by Stop and the span
    // is closed at SessionEnd. Codex has neither event nor transcript_path, so
    // it keeps the synchronous PostToolUse record (+ ingest-codex backfill).
    if (agent !== "codex") {
      specs.push({ event: "Stop",       matcher: "", cmd: `${hooksDir}/stop-trace.sh` });
      specs.push({ event: "SessionEnd", matcher: "", cmd: `${hooksDir}/session-end.sh` });
    }
    for (const s of specs) {
      c.hooks[s.event] = Array.isArray(c.hooks[s.event]) ? c.hooks[s.event] : [];
      const exists = c.hooks[s.event].some(g =>
        Array.isArray(g.hooks) && g.hooks.some(h => h && h.command === s.cmd));
      if (!exists) c.hooks[s.event].push({ matcher: s.matcher, hooks: [{ type: "command", command: s.cmd }] });
    }
    fs.writeFileSync(file, JSON.stringify(c, null, 2));
  ' "$target" "$HOOKS_DIR" "$agent"
}

if [ -f "$HOOK_CMD" ] && has_cmd node; then
  [ -f "$CLAUDE_SETTINGS" ] || { mkdir -p "$(dirname "$CLAUDE_SETTINGS")"; printf '{}\n' > "$CLAUDE_SETTINGS"; }
  register_loop_hooks "$CLAUDE_SETTINGS" claude 2>/dev/null \
    && ok "Learning loop: trace capture + auto-tune enabled for Claude Code (local only)" \
    || warn "Could not register Claude hooks — skills still work, tracing stays off"
  if register_loop_hooks "$CODEX_HOOKS" codex 2>/dev/null; then
    ok "Learning loop: trace capture enabled for Codex (~/.codex/hooks.json)"
  fi
elif ! has_cmd node; then
  warn "node not found — trace capture disabled (optimize/bench still work on existing traces)"
fi

# --- Raven MCP: Stellar docs + live ecosystem data for every agent/persona ---
# Raven (raven.stellar.buzz) is the official hosted MCP server for the Stellar
# ecosystem — `search` over docs + ecosystem, `execute` against live data. The
# personas lean on it for ground truth, so we wire it up at install time.
# The playground on the site is a demo; agents connect to the MCP directly.
RAVEN_URL="https://raven.stellar.buzz/mcp"
RAVEN_CLAUDE=false
RAVEN_CODEX=false
log "Connecting Raven MCP (raven.stellar.buzz)..."
# Claude Code MCP config is global — only touch it for real (non --prefix) installs.
if [ "$PREFIX" = "$HOME" ] && has_cmd claude; then
  if claude mcp get stellar-raven >/dev/null 2>&1; then
    # Carry ownership forward across --update runs so uninstall still cleans up.
    grep -q '"ravenClaude":true' "$MANIFEST_FILE" 2>/dev/null && RAVEN_CLAUDE=true
    ok "Raven MCP already connected in Claude Code"
  elif claude mcp add --transport http --scope user stellar-raven "$RAVEN_URL" >/dev/null 2>&1; then
    RAVEN_CLAUDE=true
    ok "Raven MCP connected for Claude Code (OAuth sign-in on first use)"
  else
    warn "Could not add Raven MCP — add manually: claude mcp add --transport http stellar-raven $RAVEN_URL"
  fi
elif [ "$PREFIX" != "$HOME" ]; then
  warn "Sandbox install — skipping global Claude MCP registration"
fi
# Codex reaches HTTP MCP servers through the mcp-remote bridge in config.toml.
CODEX_CONFIG="$PREFIX/.codex/config.toml"
if [ -d "$PREFIX/.codex" ] || [ "$PREFIX" != "$HOME" ]; then
  mkdir -p "$PREFIX/.codex"
  if ! grep -q '\[mcp_servers\.stellar-raven\]' "$CODEX_CONFIG" 2>/dev/null; then
    printf '\n[mcp_servers.stellar-raven]\ncommand = "npx"\nargs = ["-y", "mcp-remote", "%s"]\n' "$RAVEN_URL" >> "$CODEX_CONFIG"
    RAVEN_CODEX=true
    ok "Raven MCP wired for Codex (config.toml via mcp-remote)"
  else
    grep -q '"ravenCodex":true' "$MANIFEST_FILE" 2>/dev/null && RAVEN_CODEX=true
    ok "Raven MCP already wired for Codex"
  fi
fi

# Registering the server is not the same as being signed in. Raven is OAuth-gated
# (authorization_code + PKCE only — no service tokens), so without this check the
# user finds out at the first 401, mid-task. `claude mcp get` is health-checked,
# so "Connected" means the stored token actually works. We offer the one-time
# browser sign-in here, while they're still at the terminal — but only when
# there's a real TTY, so piped/CI installs stay non-interactive.
if [ "$PREFIX" = "$HOME" ] && has_cmd claude; then
  if claude mcp get stellar-raven 2>/dev/null | grep -q "Connected"; then
    ok "Raven signed in for Claude Code"
  elif [ -n "${STELLAR_BUILD_NO_RAVEN_LOGIN:-}" ]; then
    warn "Raven needs a one-time sign-in: stellar-loop raven login"
  elif [ -t 1 ] && [ -r /dev/tty ]; then
    # curl | bash leaves stdin pointed at the script, so read from the terminal.
    printf "\n  %s?%s Raven needs a one-time sign-in. Do it now (opens a browser)? %s[Y/n]%s " \
      "$CYAN" "$RESET" "$DIM" "$RESET"
    RAVEN_REPLY=""
    read -r RAVEN_REPLY < /dev/tty || RAVEN_REPLY=""
    case "$RAVEN_REPLY" in
      n|N|no|NO|No)
        warn "Skipped — run 'stellar-loop raven login' when you're ready" ;;
      *)
        # SSH sessions can't open a browser; --no-browser prints a pasteable URL.
        RAVEN_LOGIN_FLAG=""
        [ -n "${SSH_CONNECTION:-}${SSH_TTY:-}" ] && RAVEN_LOGIN_FLAG="--no-browser"
        if claude mcp login stellar-raven $RAVEN_LOGIN_FLAG </dev/tty; then
          ok "Raven signed in for Claude Code"
        else
          warn "Sign-in didn't complete — retry any time: stellar-loop raven login"
        fi ;;
    esac
  else
    warn "Raven needs a one-time sign-in: stellar-loop raven login"
  fi
fi
# Codex authenticates through mcp-remote's own cache (~/.mcp-auth) and stays
# resident once started, so we don't drive that flow from the installer.
if $RAVEN_CODEX && [ ! -d "$PREFIX/.mcp-auth" ]; then
  warn "Codex needs its own Raven sign-in: stellar-loop raven login codex"
fi

# --- Manifest ---
SKILL_PATHS_JSON=""
for s in $FOLDER_SKILLS; do
  SKILL_PATHS_JSON="${SKILL_PATHS_JSON}\"$CLAUDE_SKILLS/$s\",\"$CODEX_SKILLS/$s\","
done
for s in $FLAT_SKILLS; do
  SKILL_PATHS_JSON="${SKILL_PATHS_JSON}\"$CLAUDE_SKILLS/$s.md\",\"$CODEX_SKILLS/$s.md\","
done
SKILL_PATHS_JSON="${SKILL_PATHS_JSON%,}"

PERMS_JSON=""
if [ -n "$PERMS_ADDED" ]; then
  PERMS_JSON=$(echo "$PERMS_ADDED" | tr ',' '\n' | sed 's/.*/"&"/' | tr '\n' ',' | sed 's/,$//')
fi

cat > "$MANIFEST_FILE" <<MANIFEST
{"installedBy":"$PRODUCT_NAME","installedAt":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","prefix":"$PREFIX","skillPaths":[$SKILL_PATHS_JSON],"sharedPaths":["$CLAUDE_SKILLS/data","$CLAUDE_SKILLS/SKILL_ROUTER.md","$CODEX_SKILLS/data","$CODEX_SKILLS/SKILL_ROUTER.md"],"permissionsAdded":[$PERMS_JSON],"traceHook":"$HOOK_CMD","hooksDir":"$HOOKS_DIR","codexHooks":"$CODEX_HOOKS","settingsFile":"$CLAUDE_SETTINGS","ravenClaude":$RAVEN_CLAUDE,"ravenCodex":$RAVEN_CODEX}
MANIFEST
ok "Wrote manifest to $MANIFEST_FILE"

# --- Welcome card ---
_welcome_card() {
  local R=$'\033[0m'
  local Y=$'\033[1;38;5;220m'   # bright yellow — logo + persona names
  local C=$'\033[0;36m'         # cyan — prompts
  local G=$'\033[0;32m'         # green — arrows
  local B=$'\033[1m'            # bold — wordmark + section headers
  local D=$'\033[2m'            # dim — captions, dividers
  local K=$'\033[38;5;244m'     # grey — separators (·)

  echo ""
  # Stellar logo, top-left
  printf "${Y}%s${R}\n" "              █████████"
  printf "${Y}%s${R}\n" "           █████     █████     ███"
  printf "${Y}%s${R}\n" "         ███               █████"
  printf "${Y}%s${R}\n" "       ███             ██████"
  printf "${Y}%s${R}\n" "       ██           █████     ████"
  printf "${Y}%s${R}\n" "      ██        █████      █████"
  printf "${Y}%s${R}\n" "      ██     █████     █████ ██"
  printf "${Y}%s${R}\n" "      ██ █████     █████     ██"
  printf "${Y}%s${R}\n" "     ██████     █████        ██"
  printf "${Y}%s${R}\n" "   ████     █████           ██"
  printf "${Y}%s${R}\n" "         █████             ███"
  printf "${Y}%s${R}\n" "     █████               ███"
  printf "${Y}%s${R}\n" "   ███      ████     █████"
  printf "${Y}%s${R}\n" "              █████████"
  echo ""
  printf "   ${B}stellar-build${R}\n"
  printf "   ${D}─────────────${R}\n"
  printf "   ${D}Your Stellar dev journey from idea to mainnet${R}\n"
  echo ""
  echo ""

  # Team
  printf "${D}──${R}  ${B}YOUR TEAM${R} ${D}(just say their name)${R} ${D}─────────────────────────────${R}\n"
  echo ""
  printf "  ${Y}JUSTIN${R}    analyst       ${K}·${R}  market research, validation\n"
  printf "  ${Y}BRI${R}       tech writer   ${K}·${R}  docs, knowledge curation\n"
  printf "  ${Y}NICOLE${R}    pm            ${K}·${R}  PRDs, requirements\n"
  printf "  ${Y}KAAN${R}      ux designer   ${K}·${R}  interaction design\n"
  printf "  ${Y}TYLER${R}     architect     ${K}·${R}  system + soroban design\n"
  printf "  ${Y}ELLIOT${R}    senior dev    ${K}·${R}  story execution, code\n"
  echo ""

  # First prompts
  printf "${D}──${R}  ${B}FIRST PROMPTS${R} ${D}──────────────────────────────────────────────${R}\n"
  echo ""
  printf "  ${G}→${R}  ${C}\"what should I build on Stellar?\"${R}\n"
  printf "  ${G}→${R}  ${C}\"current SCF round\"${R}\n"
  printf "  ${G}→${R}  ${C}\"talk to Tyler\"${R}\n"
  printf "  ${G}→${R}  ${C}/stellar-help${R}                ${D}← if you get lost${R}\n"
  printf "  ${G}→${R}  ${C}/navigate-skills${R}             ${D}← see all ${SKILL_COUNT} skills${R}\n"
  printf "  ${G}→${R}  ${C}/optimize-skills${R}             ${D}← your skills learn from how you use them${R}\n"
  echo ""

  # Learning loop
  printf "${D}──${R}  ${B}LEARNING LOOP${R} ${D}(local, private, fully automatic)${R} ${D}────────────────${R}\n"
  echo ""
  printf "  Self-improving, hands-free: every prompt is auto-sharpened, every skill\n"
  printf "  run is traced locally, and your skills auto-retune in the background once\n"
  printf "  enough usage builds up. The more you use it, the better it fits you.\n"
  printf "  ${D}Check it:${R} ${C}stellar-loop status${R}   ${D}Off:${R} ${C}STELLAR_BUILD_NO_LOOP=1 / NO_REPROMPT=1${R}\n"
  echo ""

  # Footer stats
  printf "  ${D}${SKILL_COUNT} skills installed${R} ${K}·${R} ${D}728 ecosystem projects${R} ${K}·${R} ${D}9027 catalogued repos${R}\n"
  echo ""
}
_welcome_card

# --- Done ---
if [ "$UPDATE_MODE" = true ]; then
  printf "  %s%sUpdate complete!%s %s%s skills updated.%s\n\n" "$GREEN" "$BOLD" "$RESET" "$DIM" "$SKILL_COUNT" "$RESET"
else
  printf "  %s%sSetup complete!%s\n\n" "$GREEN" "$BOLD" "$RESET"
fi

# Anonymous install counter (Abacus, CountAPI's successor).
# No identity, no IP collection on our side — just a single counter increment
# so the maintainer can see rough usage. Opt out: STELLAR_BUILD_NO_TELEMETRY=1
if [ -z "${STELLAR_BUILD_NO_TELEMETRY:-}" ] && has_cmd curl; then
  event="install"
  [ "$UPDATE_MODE" = true ] && event="update"
  curl -fsSL "https://abacus.jasoncameron.dev/hit/kaankacar.stellar-build/${event}" >/dev/null 2>&1 &
fi

# Git-repo hint for project-local installs.
# /party-mode spawns each persona as an isolated subagent using git worktrees,
# which need: (a) a git repo + (b) at least one commit (an empty commit works).
# Only show this hint when installing to a non-HOME prefix that lacks a git repo.
if [ "$PREFIX" != "$HOME" ] && [ ! -d "$PREFIX/.git" ]; then
  printf "  %sTip:%s for multi-agent /party-mode to spawn isolated subagents,\n" "$YELLOW" "$RESET"
  printf "  initialize this folder as a git repo with at least one commit:\n"
  printf "    %scd %s && git init && git commit --allow-empty -m init%s\n\n" "$CYAN" "$PREFIX" "$RESET"
fi

# Learning-loop CLI PATH hint — stellar-loop lives in the config dir's bin/.
if [ -x "$CONFIG_DIR/bin/stellar-loop" ] && ! has_cmd stellar-loop; then
  printf "  %sTip:%s manage the learning loop with %sstellar-loop%s. Add it to PATH:\n" "$YELLOW" "$RESET" "$CYAN" "$RESET"
  printf "    %sexport PATH=\"\$PATH:%s/bin\"%s\n\n" "$CYAN" "$CONFIG_DIR" "$RESET"
fi

# Uninstall hint — only show --prefix flag if user passed one (otherwise default $HOME)
uninstall_suffix=""
[ "$PREFIX" != "$HOME" ] && uninstall_suffix=" --prefix=$PREFIX"
printf "  %sUninstall later:%s ./install.sh --uninstall%s\n\n" "$DIM" "$RESET" "$uninstall_suffix"
