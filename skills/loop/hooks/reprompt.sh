#!/usr/bin/env bash
# stellar-build learning loop — automatic prompt sharpener wrapper.
# Registered as a UserPromptSubmit hook on both Claude Code and Codex. Prints a
# compact "sharpen the request" directive (+ learned profile) that the host
# injects into context. Always exits 0. Opt out: STELLAR_BUILD_NO_REPROMPT=1.
set +e

# Don't reprompt the optimizer's own background runs.
[ -n "${STELLAR_LOOP_AUTORUN:-}" ] && exit 0

case "${STELLAR_BUILD_NO_REPROMPT:-}" in
  1|true|yes|on|TRUE|Yes|On|YES) exit 0 ;;
esac

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd 2>/dev/null)" || exit 0

if command -v node >/dev/null 2>&1; then
  node "$HOOK_DIR/reprompt.js" 2>/dev/null
else
  cat >/dev/null 2>&1
fi

exit 0
