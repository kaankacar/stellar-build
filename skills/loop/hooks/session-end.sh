#!/usr/bin/env bash
# stellar-build learning loop — span closer wrapper (SessionEnd).
#
# Registered as a SessionEnd hook on Claude Code. Hands the event JSON (stdin)
# to session-end.js, which closes any open skill span with one kind:"span"
# record and bumps the activation counter once. Always exits 0.
#
# Cheap gate: only spawn node if an active-skill pointer exists.
#
# Opt out: export STELLAR_BUILD_NO_TRACE=1
set +e

[ -n "${STELLAR_BUILD_NO_TRACE:-}" ] && { cat >/dev/null 2>&1; exit 0; }
[ -n "${STELLAR_LOOP_AUTORUN:-}" ] && { cat >/dev/null 2>&1; exit 0; }

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd 2>/dev/null)" || { cat >/dev/null 2>&1; exit 0; }

command -v node >/dev/null 2>&1 || { cat >/dev/null 2>&1; exit 0; }

ACTIVE_DIR="${STELLAR_HOME:-$HOME/.stellar}/.active"
if ! ls "$ACTIVE_DIR"/*.json >/dev/null 2>&1; then
  cat >/dev/null 2>&1
  exit 0
fi

node "$HOOK_DIR/session-end.js" 2>/dev/null

exit 0
