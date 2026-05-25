#!/usr/bin/env bash
# rename-bmad.sh — pull selected BMAD skills, rename folders + name: fields,
# swap personas for SDF DevRel team. Idempotent: clears methodology/ each run.
#
# Usage:
#   ./tools/rename-bmad.sh
#
# Override BMAD source location with BMAD_SRC env var if needed.
#
# Requires: perl (ships with macOS by default).

set -euo pipefail

# Resolve script dir + repo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Resolve BMAD source path — tries env var, then default global npm location
if [ -z "${BMAD_SRC:-}" ]; then
  for candidate in \
    "$HOME/.nvm/versions/node/v24.15.0/lib/node_modules/bmad-method/src" \
    "$(npm root -g 2>/dev/null)/bmad-method/src" \
    "/usr/local/lib/node_modules/bmad-method/src"; do
    if [ -d "$candidate" ]; then
      BMAD_SRC="$candidate"
      break
    fi
  done
fi

if [ -z "${BMAD_SRC:-}" ] || [ ! -d "$BMAD_SRC" ]; then
  echo "✗ BMAD source not found. Install with: npm install -g bmad-method"
  echo "  Or set BMAD_SRC=/path/to/bmad-method/src"
  exit 1
fi

DEST="$REPO_ROOT/skills/methodology"
echo "→ BMAD source: $BMAD_SRC"
echo "→ Target:      $DEST"

# Skill mappings: <source_path_in_bmad>|<target_folder_name>
SKILLS=(
  "core-skills/bmad-brainstorming|brainstorming"
  "core-skills/bmad-advanced-elicitation|advanced-elicitation"
  "core-skills/bmad-party-mode|party-mode"
  "core-skills/bmad-help|stellar-help"
  "core-skills/bmad-review-edge-case-hunter|review-edge-case-hunter"
  "bmm-skills/1-analysis/bmad-agent-analyst|justin-analyst"
  "bmm-skills/1-analysis/bmad-agent-tech-writer|bri-tech-writer"
  "bmm-skills/1-analysis/bmad-prfaq|prfaq"
  "bmm-skills/1-analysis/bmad-product-brief|product-brief"
  "bmm-skills/2-plan-workflows/bmad-agent-pm|nicole-pm"
  "bmm-skills/2-plan-workflows/bmad-agent-ux-designer|kaan-ux-designer"
  "bmm-skills/2-plan-workflows/bmad-prd|prd"
  "bmm-skills/2-plan-workflows/bmad-create-ux-design|create-ux-design"
  "bmm-skills/3-solutioning/bmad-agent-architect|tyler-architect"
  "bmm-skills/3-solutioning/bmad-create-architecture|create-architecture"
  "bmm-skills/3-solutioning/bmad-create-epics-and-stories|create-epics-and-stories"
  "bmm-skills/4-implementation/bmad-agent-dev|elliot-dev"
  "bmm-skills/4-implementation/bmad-dev-story|dev-story"
  "bmm-skills/4-implementation/bmad-investigate|investigate"
  "bmm-skills/4-implementation/bmad-code-review|code-review"
)

# Persona swaps: <original>|<new>
PERSONAS=(
  "Mary|Justin"
  "Paige|Bri"
  "John|Nicole"
  "Sally|Kaan"
  "Winston|Tyler"
  "Amelia|Elliot"
)

# --- Step 1: Clean and copy ---
echo ""
echo "→ Copying ${#SKILLS[@]} BMAD skills"
rm -rf "$DEST"
mkdir -p "$DEST"

copied=0
for entry in "${SKILLS[@]}"; do
  src_rel="${entry%|*}"
  target="${entry#*|}"
  src="$BMAD_SRC/$src_rel"
  if [ ! -d "$src" ]; then
    echo "  ! Skipping missing: $src_rel"
    continue
  fi
  cp -R "$src" "$DEST/$target"
  copied=$((copied + 1))
  echo "  ✓ $src_rel → $target"
done

# --- Step 2: Update name: frontmatter to match new folder name ---
echo ""
echo "→ Aligning SKILL.md name: fields with folder names"
for entry in "${SKILLS[@]}"; do
  target="${entry#*|}"
  skill_md="$DEST/$target/SKILL.md"
  [ -f "$skill_md" ] || continue
  perl -i -pe "s/^name: .+\$/name: $target/" "$skill_md"
done

# --- Step 3: Persona name swaps across SKILL.md, customize.toml, and supporting .md ---
echo ""
echo "→ Applying persona name swaps (word-boundary aware)"
for entry in "${PERSONAS[@]}"; do
  orig="${entry%|*}"
  new="${entry#*|}"
  # \b is supported by perl on macOS; safe across SKILL.md, customize.toml, and any
  # template/workflow markdown that lives inside skill folders.
  find "$DEST" -type f \( -name "SKILL.md" -o -name "customize.toml" -o -name "*.md" \) \
    -exec perl -i -pe "s/\b${orig}\b/${new}/g" {} \;
  echo "  ✓ $orig → $new"
done

# --- Step 3b: Rename BMAD config path references _bmad/ → .stellar-build/ ---
# Skills reference a project-local config dir for persona/agent customization.
# Upstream BMAD calls it _bmad/; we rebrand so the leaked path doesn't show
# BMAD plumbing in user-facing messages.
echo ""
echo "→ Renaming _bmad/ config paths to .stellar-build/"
find "$DEST" -type f \( -name "SKILL.md" -o -name "customize.toml" -o -name "*.md" \) \
  -exec perl -i -pe "s|_bmad/|.stellar-build/|g" {} \;
echo "  ✓ All _bmad/ path references rewritten"

# --- Step 4: Sanity verification ---
echo ""
echo "→ Verifying"
skill_count=$(find "$DEST" -name "SKILL.md" -maxdepth 2 | wc -l | tr -d ' ')
echo "  $skill_count SKILL.md files in $DEST"

# Check name: matches folder
mismatches=0
for entry in "${SKILLS[@]}"; do
  target="${entry#*|}"
  skill_md="$DEST/$target/SKILL.md"
  [ -f "$skill_md" ] || continue
  actual_name=$(grep -m1 "^name:" "$skill_md" | sed 's/^name: *//')
  if [ "$actual_name" != "$target" ]; then
    echo "  ! Mismatch: $target folder has name: $actual_name"
    mismatches=$((mismatches + 1))
  fi
done

# Check no original persona names remain. `grep -rwl` returns 1 when nothing
# matches (which is success for us), so swallow it explicitly.
leftover=0
for entry in "${PERSONAS[@]}"; do
  orig="${entry%|*}"
  matches=$(grep -rwl "$orig" "$DEST" 2>/dev/null || true)
  if [ -n "$matches" ]; then
    count=$(echo "$matches" | wc -l | tr -d ' ')
    echo "  ! '$orig' still appears in $count files"
    leftover=$((leftover + count))
  fi
done

echo ""
if [ "$mismatches" = "0" ] && [ "$leftover" = "0" ]; then
  echo "✓ Done. $copied skills, all name: fields aligned, all personas swapped."
else
  echo "⚠ Done with issues. $copied skills, $mismatches name: mismatches, $leftover leftover persona references."
  exit 1
fi
