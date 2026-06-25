#!/usr/bin/env bash
# stellar-build learning loop — per-turn trace writer wrapper (Stop).
#
# Registered as a Stop hook on Claude Code. Hands the event JSON (stdin) to
# stop-trace.js, which appends one kind:"turn" record IF a skill is resident
# this session. Always exits 0 so it can never block a turn.
#
# Cheap gate: Stop fires every turn, but we only need node when a skill span is
# actually open. If there are no active pointers, drain stdin and no-op.
#
# Opt out: export STELLAR_BUILD_NO_TRACE=1
set +e

[ -n "${STELLAR_BUILD_NO_TRACE:-}" ] && { cat >/dev/null 2>&1; exit 0; }
[ -n "${STELLAR_LOOP_AUTORUN:-}" ] && { cat >/dev/null 2>&1; exit 0; }

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd 2>/dev/null)" || { cat >/dev/null 2>&1; exit 0; }

command -v node >/dev/null 2>&1 || { cat >/dev/null 2>&1; exit 0; }

# Skip the node spawn unless at least one active-skill pointer exists.
ACTIVE_DIR="${STELLAR_HOME:-$HOME/.stellar}/.active"
if ! ls "$ACTIVE_DIR"/*.json >/dev/null 2>&1; then
  cat >/dev/null 2>&1
  exit 0
fi

node "$HOOK_DIR/stop-trace.js" 2>/dev/null

exit 0
