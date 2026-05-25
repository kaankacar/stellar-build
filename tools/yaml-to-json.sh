#!/usr/bin/env bash
# yaml-to-json.sh — convert lumenloop/stellar-ecosystem-db YAMLs to JSON catalogs
#
# Produces under skills/data/lumenloop/:
#   projects.json             — flat array of all 728 projects
#   scf/rounds.json           — { round_name: { projects: [...], total_awarded } }
#   audits/registry.json      — flat array of all audit records, keyed back to project
#   tokens/registry.json      — flat array of all token records
#
# Uses uv to provide PyYAML if not already installed.
#
# Override input location with INPUT_DIR env var.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

INPUT_DIR="${INPUT_DIR:-$REPO_ROOT/sources/stellar-ecosystem-db/projects}"
OUT_DIR="$REPO_ROOT/skills/data/lumenloop"

if [ ! -d "$INPUT_DIR" ]; then
  echo "✗ Source YAMLs not found at $INPUT_DIR"
  echo "  Clone: git clone https://github.com/lumenloop/stellar-ecosystem-db.git"
  echo "  Or set INPUT_DIR=/path/to/projects"
  exit 1
fi

mkdir -p "$OUT_DIR/scf" "$OUT_DIR/audits" "$OUT_DIR/tokens"

echo "→ Converting YAMLs from $INPUT_DIR"
echo "→ Output:                  $OUT_DIR"

# Use system Python if PyYAML is available; otherwise fall back to uv.
if python3 -c "import yaml" 2>/dev/null; then
  PY_CMD=(python3)
elif command -v uv >/dev/null 2>&1; then
  PY_CMD=(uv run --quiet --with pyyaml python3)
else
  echo "✗ Need PyYAML. Install: pip install pyyaml  OR  brew install uv"
  exit 1
fi

"${PY_CMD[@]}" - "$INPUT_DIR" "$OUT_DIR" <<'PYEOF'
import yaml, json, glob, os, sys
from pathlib import Path

input_dir = sys.argv[1]
out_dir = sys.argv[2]

projects = []
for yaml_path in sorted(glob.glob(f"{input_dir}/*.yaml")):
    try:
        with open(yaml_path) as f:
            data = yaml.safe_load(f)
        if data:
            data['_slug'] = Path(yaml_path).stem
            projects.append(data)
    except Exception as e:
        print(f"  ! Skipped {yaml_path}: {e}", file=sys.stderr)

# 1. Master projects.json
with open(f"{out_dir}/projects.json", 'w') as f:
    json.dump(projects, f, separators=(',', ':'))

# 2. SCF rounds index — { round_name: { projects: [...], total_awarded: N } }
rounds = {}
for p in projects:
    scf = p.get('scf') or {}
    for r in (scf.get('awarded_round') or []):
        rounds.setdefault(r, {'projects': [], 'total_awarded': 0})
        rounds[r]['projects'].append({
            'slug': p['_slug'],
            'title': p.get('title'),
            'category': (p.get('attributes') or {}).get('category'),
            'awarded_total': scf.get('awarded_total'),
        })
        if scf.get('awarded_total'):
            rounds[r]['total_awarded'] += scf['awarded_total']
with open(f"{out_dir}/scf/rounds.json", 'w') as f:
    json.dump(rounds, f, separators=(',', ':'))

# 3. Audits registry
audits = []
for p in projects:
    mainnet = p.get('mainnet') or {}
    for audit in (mainnet.get('audits') or []):
        audits.append({
            'project_slug': p['_slug'],
            'project_title': p.get('title'),
            **audit,
        })
with open(f"{out_dir}/audits/registry.json", 'w') as f:
    json.dump(audits, f, separators=(',', ':'))

# 4. Tokens registry
tokens = []
for p in projects:
    mainnet = p.get('mainnet') or {}
    for tok in (mainnet.get('tokens') or []):
        tokens.append({
            'project_slug': p['_slug'],
            'project_title': p.get('title'),
            **tok,
        })
with open(f"{out_dir}/tokens/registry.json", 'w') as f:
    json.dump(tokens, f, separators=(',', ':'))

print(f"✓ {len(projects)} projects → projects.json")
print(f"✓ {len(rounds)} SCF rounds indexed → scf/rounds.json")
print(f"✓ {len(audits)} audit records → audits/registry.json")
print(f"✓ {len(tokens)} token records → tokens/registry.json")
PYEOF
