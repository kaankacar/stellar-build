#!/usr/bin/env bash
# stellar-build learning loop — prompt capture wrapper (UserPromptSubmit).
# Stashes the latest prompt per session for demo pairing. Prints nothing to
# stdout (that would be injected into context). Always exits 0.
set +e

[ -n "${STELLAR_BUILD_NO_TRACE:-}" ] && exit 0

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd 2>/dev/null)" || exit 0

if command -v node >/dev/null 2>&1; then
  node "$HOOK_DIR/capture-prompt.js" 2>/dev/null
else
  cat >/dev/null 2>&1
fi

exit 0
