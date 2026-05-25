#!/usr/bin/env bash
# bootstrap-sources.sh — clone all the upstream source repos that the build
# tools (yaml-to-json.sh, electric-capital-export.sh, curate-ecosystem-resources.sh)
# read from. After this runs, the build tools work with their default paths.
#
# Usage:
#   ./tools/bootstrap-sources.sh
#
# Override target dir with SOURCES_DIR=/path env var.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

SOURCES_DIR="${SOURCES_DIR:-$REPO_ROOT/sources}"
mkdir -p "$SOURCES_DIR"

REPOS=(
  "https://github.com/lumenloop/stellar-ecosystem-db.git"
  "https://github.com/lumenloop/awesome-stellar-community-fund.git"
  "https://github.com/stellar/stellar-dev-skill.git"
  "https://github.com/stellar/ecosystem-resources.git"
  "https://github.com/electric-capital/open-dev-data.git"
)

echo "→ Cloning ${#REPOS[@]} source repos into $SOURCES_DIR"

for url in "${REPOS[@]}"; do
  name=$(basename "$url" .git)
  target="$SOURCES_DIR/$name"
  if [ -d "$target/.git" ]; then
    echo "  ↻ $name already cloned, pulling latest"
    (cd "$target" && git pull --quiet)
  else
    echo "  ⬇ Cloning $name"
    git clone --depth=1 --quiet "$url" "$target"
  fi
done

echo ""
echo "✓ Sources ready in $SOURCES_DIR"
echo ""
echo "Next steps:"
echo "  ./tools/yaml-to-json.sh                  # convert ecosystem-db YAMLs to JSON catalogs"
echo "  ./tools/electric-capital-export.sh       # export Electric Capital Stellar repo list"
echo "  ./tools/curate-ecosystem-resources.sh    # pull text guides from ecosystem-resources"
echo "  ./tools/rename-bmad.sh                   # paraphrase BMAD skills (needs bmad-method installed globally)"
echo "  ./build.sh                               # tar up skills/ to bundle.tar.gz"
