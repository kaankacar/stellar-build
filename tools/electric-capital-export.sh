#!/usr/bin/env bash
# electric-capital-export.sh — export the Stellar ecosystem from Electric Capital's
# open-dev-data taxonomy into a JSONL file the skills can grep.
#
# Output: skills/data/electric-capital/stellar-repos.jsonl
#
# Requires: uv (curl -LsSf https://astral.sh/uv/install.sh | sh)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

OUT_DIR="$REPO_ROOT/skills/data/electric-capital"
mkdir -p "$OUT_DIR"

# open-dev-data needs a migrations directory. Point at our cloned source
# (override with ODD_REPO env var if elsewhere).
ODD_REPO="${ODD_REPO:-$REPO_ROOT/sources/open-dev-data}"
MIGRATIONS_DIR="$ODD_REPO/migrations"

if [ ! -d "$MIGRATIONS_DIR" ]; then
  echo "✗ open-dev-data migrations not found at $MIGRATIONS_DIR"
  echo "  Clone: git clone https://github.com/electric-capital/open-dev-data.git"
  echo "  Or set ODD_REPO=/path/to/open-dev-data"
  exit 1
fi

if ! command -v uv >/dev/null 2>&1; then
  echo "✗ uv not found. Install: curl -LsSf https://astral.sh/uv/install.sh | sh"
  exit 1
fi

OUT_FILE="$OUT_DIR/stellar-repos.json"

echo "→ Running open-dev-data export against migrations dir"
echo "  Output: $OUT_FILE"

uvx open-dev-data export --root "$MIGRATIONS_DIR" --ecosystem Stellar "$OUT_FILE"

# open-dev-data outputs JSON Lines (one JSON object per line) despite the .json extension
count=$(wc -l < "$OUT_FILE" | tr -d ' ')
size=$(du -h "$OUT_FILE" | cut -f1)
echo "✓ Exported $count records ($size) to $OUT_FILE"
