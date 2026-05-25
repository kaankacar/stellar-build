#!/usr/bin/env bash
# Build a distributable bundle.tar.gz from skills/
set -euo pipefail

cd "$(dirname "$0")"

rm -f bundle.tar.gz
tar -czf bundle.tar.gz skills/

SIZE=$(du -h bundle.tar.gz | cut -f1)
SKILL_COUNT=$(find skills -name SKILL.md | wc -l | tr -d ' ')

echo "Built bundle.tar.gz (${SIZE}, ${SKILL_COUNT} skills)"
