#!/usr/bin/env bash
# Load the real installer helpers (single source of truth in install.sh).
# Usage: source this file from regression tests.
set -euo pipefail

_MCP_HELPERS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# Clear positional args so install.sh flag parsing sees none.
set --
# shellcheck disable=SC2034
STELLAR_BUILD_LIB_ONLY=1
# shellcheck disable=SC1091
source "$_MCP_HELPERS_ROOT/install.sh"
