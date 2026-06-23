#!/usr/bin/env bash
# stellar-build learning loop — self-trigger wrapper (SessionStart).
# Lets the loop decide, at session start, whether enough new usage has
# accumulated to nudge or auto-optimize. stdout is injected as context by the
# host agent, so loop-session-start.js prints at most one short line. Exits 0.
set +e

# Recursion guard: an automated optimize run must not re-trigger the loop.
[ -n "${STELLAR_LOOP_AUTORUN:-}" ] && exit 0

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd 2>/dev/null)" || exit 0

command -v node >/dev/null 2>&1 || exit 0
node "$HOOK_DIR/loop-session-start.js" 2>/dev/null

exit 0
