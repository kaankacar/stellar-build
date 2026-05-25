#!/usr/bin/env bash
# curate-ecosystem-resources.sh — pull the small, text-only folders from
# stellar/ecosystem-resources into skills/data/guides/.
#
# Heavy folders (connect-wallet, guestbook, openzeppelin, kale*, stellar-quest)
# are referenced via LINKS.md, not bundled.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

INPUT_DIR="${INPUT_DIR:-$REPO_ROOT/../solananew/sources/ecosystem-resources}"
OUT_DIR="$REPO_ROOT/skills/data/guides"

if [ ! -d "$INPUT_DIR" ]; then
  echo "✗ ecosystem-resources not found at $INPUT_DIR"
  echo "  Clone: git clone https://github.com/stellar/ecosystem-resources.git"
  echo "  Or set INPUT_DIR=/path/to/ecosystem-resources"
  exit 1
fi

mkdir -p "$OUT_DIR"

# Small text-only folders to include
INCLUDE=(
  "defi"
  "oracles"
  "security"
  "soroban-development"
  "tokens"
  "learning"
  "infrastructure"
  "building-with-ai"
  "indexers"
  "fca00c"
)

echo "→ Curating ecosystem-resources from $INPUT_DIR"

copied_total=0
for folder in "${INCLUDE[@]}"; do
  src="$INPUT_DIR/$folder"
  if [ ! -d "$src" ]; then
    continue
  fi
  mkdir -p "$OUT_DIR/$folder"
  found=0
  while IFS= read -r -d '' md_file; do
    cp "$md_file" "$OUT_DIR/$folder/"
    found=$((found + 1))
  done < <(find "$src" -maxdepth 2 -name "*.md" -print0)
  if [ $found -gt 0 ]; then
    echo "  ✓ $folder ($found markdown files)"
    copied_total=$((copied_total + found))
  fi
done

# Add LINKS.md for heavy folders we don't bundle
cat > "$OUT_DIR/LINKS.md" <<'EOF'
# Heavy ecosystem-resources folders (linked, not bundled)

The following folders from stellar/ecosystem-resources are too large to bundle
(images, video assets, tutorial codebases). Visit them directly:

- [Connect Wallet Workshop](https://github.com/stellar/ecosystem-resources/tree/main/connect-wallet) — Freighter, Stellar Wallets Kit, Smart Account Kit
- [Guestbook Tutorial](https://github.com/stellar/ecosystem-resources/tree/main/guestbook) — Full dapp tutorial
- [OpenZeppelin Tools](https://github.com/stellar/ecosystem-resources/tree/main/openzeppelin) — Audited contracts and tooling
- [KALE Mining](https://github.com/stellar/ecosystem-resources/tree/main/kale) — Mining dapp walkthrough
- [KALEFAIL Trading](https://github.com/stellar/ecosystem-resources/tree/main/kalefail) — Trading post tutorial
- [Stellar Quest](https://github.com/stellar/ecosystem-resources/tree/main/stellar-quest) — Interactive learning (WIP)

These are full repos with assets; if a skill needs deep code references, fetch from upstream rather than expect them locally.
EOF

echo ""
echo "✓ Copied $copied_total markdown files from ${#INCLUDE[@]} folders"
echo "✓ Wrote LINKS.md pointing at heavy folders"
