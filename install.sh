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

PRODUCT_NAME="stellar"

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
MANIFEST_FILE="$CONFIG_DIR/manifest.json"
CLAUDE_SETTINGS="$PREFIX/.claude/settings.json"

# --- Manifest helpers ---
read_manifest_array() {
  [ -f "$MANIFEST_FILE" ] || return 1
  sed -n "s/.*\"$1\":\[\([^]]*\)\].*/\1/p" "$MANIFEST_FILE" 2>/dev/null \
    | grep -o '"[^"]*"' | tr -d '"'
}

# --- Uninstall mode ---
if [ "$UNINSTALL_MODE" = true ]; then
  printf "\n  %s%sUninstalling %s...%s\n\n" "$CYAN" "$BOLD" "$PRODUCT_NAME" "$RESET"
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

  # Revert Claude Code permissions
  PERMS_TO_REMOVE=$(read_manifest_array permissionsAdded | tr '\n' ',' | sed 's/,$//')
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

  rm -rf "$CONFIG_DIR"
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
fi

# 2. SCF — flat .md files. GitHub tarballs extract with a "<repo>-<branch>" top dir.
if $SCF_AVAILABLE; then
  SCF_SKILLS_DIR=$(find "$TMP_DIR/scf" -mindepth 1 -maxdepth 2 -type d -name "skills" | head -1)
  if [ -n "$SCF_SKILLS_DIR" ] && [ -d "$SCF_SKILLS_DIR" ]; then
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
{"installedBy":"$PRODUCT_NAME","installedAt":"$(date -u +%Y-%m-%dT%H:%M:%SZ)","prefix":"$PREFIX","skillPaths":[$SKILL_PATHS_JSON],"sharedPaths":["$CLAUDE_SKILLS/data","$CLAUDE_SKILLS/SKILL_ROUTER.md","$CODEX_SKILLS/data","$CODEX_SKILLS/SKILL_ROUTER.md"],"permissionsAdded":[$PERMS_JSON],"settingsFile":"$CLAUDE_SETTINGS"}
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

# Git-repo hint for project-local installs.
# /party-mode spawns each persona as an isolated subagent using git worktrees,
# which need: (a) a git repo + (b) at least one commit (an empty commit works).
# Only show this hint when installing to a non-HOME prefix that lacks a git repo.
if [ "$PREFIX" != "$HOME" ] && [ ! -d "$PREFIX/.git" ]; then
  printf "  %sTip:%s for multi-agent /party-mode to spawn isolated subagents,\n" "$YELLOW" "$RESET"
  printf "  initialize this folder as a git repo with at least one commit:\n"
  printf "    %scd %s && git init && git commit --allow-empty -m init%s\n\n" "$CYAN" "$PREFIX" "$RESET"
fi

# Uninstall hint — only show --prefix flag if user passed one (otherwise default $HOME)
uninstall_suffix=""
[ "$PREFIX" != "$HOME" ] && uninstall_suffix=" --prefix=$PREFIX"
printf "  %sUninstall later:%s ./install.sh --uninstall%s\n\n" "$DIM" "$RESET" "$uninstall_suffix"
