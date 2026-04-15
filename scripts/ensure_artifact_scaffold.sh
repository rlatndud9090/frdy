#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

branch="${1:-$(git branch --show-current)}"
if [[ -z "$branch" ]]; then
  echo "현재 브랜치를 확인할 수 없습니다." >&2
  exit 1
fi

if [[ "$branch" == "main" ]]; then
  echo "main 브랜치에서는 새 artifact scaffold를 만들지 않습니다."
  exit 0
fi

work_unit_id="$(printf "%s" "$branch" | tr '/[:upper:]' '-[:lower:]' | sed 's/[^a-z0-9._-]/-/g')"
target_dir="$ROOT_DIR/docs/artifacts/$work_unit_id"
template_dir="$ROOT_DIR/docs/artifacts/_template"
today="$(date +%F)"

mkdir -p "$target_dir/adr" "$target_dir/meetings" "$target_dir/ai-sessions" \
  "$target_dir/experiments" "$target_dir/review-notes"

if [[ ! -f "$target_dir/meta.md" ]]; then
  sed \
    -e "s/<work-unit-id>/$work_unit_id/g" \
    -e "s#<branch-name>#$branch#g" \
    -e "s/YYYY-MM-DD/$today/g" \
    "$template_dir/meta.md" > "$target_dir/meta.md"
fi

if [[ ! -f "$target_dir/timeline.md" ]]; then
  cp "$template_dir/timeline.md" "$target_dir/timeline.md"
fi

for file in prd.md; do
  if [[ ! -f "$target_dir/$file" ]]; then
    cat > "$target_dir/$file" <<EOF
# PRD

- work-unit: $work_unit_id
- branch: $branch

## Problem

## Goal

## Constraints

## Acceptance
EOF
  fi
done

echo "$target_dir"
