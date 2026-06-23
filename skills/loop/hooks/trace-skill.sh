#!/usr/bin/env bash
# stellar-build learning loop — trace capture hook wrapper.
#
# Registered as a PostToolUse hook on Claude Code (matcher "Skill") and Codex
# (matcher ".*"). Hands the event JSON (stdin) to trace-skill.js, which appends
# a local trace record. Always exits 0 so it can never block a session.
#
# Opt out: export STELLAR_BUILD_NO_TRACE=1
set +e

[ -n "${STELLAR_BUILD_NO_TRACE:-}" ] && exit 0

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd 2>/dev/null)" || exit 0

# No node available — drain stdin and no-op. Tracing simply stays off;
# /optimize-skills and /bench-skills still work on whatever traces exist.
command -v node >/dev/null 2>&1 || { cat >/dev/null 2>&1; exit 0; }

# Codex registers this on every tool call (matcher ".*"), so cheaply pre-filter
# to actual skill invocations before paying for a node process. On Claude Code
# the matcher is already "Skill", so this is just a harmless fast path.
INPUT=$(cat 2>/dev/null)
case "$INPUT" in
  *'"skill"'*) printf '%s' "$INPUT" | node "$HOOK_DIR/trace-skill.js" 2>/dev/null ;;
  *) : ;;
esac

exit 0
