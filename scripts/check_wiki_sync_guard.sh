#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

artifacts_dir="$ROOT_DIR/docs/artifacts"

if [[ ! -d "$artifacts_dir" ]]; then
  echo "docs/artifacts 디렉터리가 없습니다."
  exit 0
fi

found=0
while IFS= read -r meta_file; do
  work_unit_dir="$(dirname "$meta_file")"
  work_unit_id="$(basename "$work_unit_dir")"
  status="$(grep '^status:' "$meta_file" | head -1 | cut -d: -f2- | xargs || true)"
  wiki_sync_status="$(grep '^wiki_sync_status:' "$meta_file" | head -1 | cut -d: -f2- | xargs || true)"
  branch="$(grep '^branch:' "$meta_file" | head -1 | cut -d: -f2- | xargs || true)"

  if [[ "$wiki_sync_status" == "pending" ]]; then
    found=1
    printf "%s|%s|%s|%s\n" "$work_unit_id" "$branch" "$status" "$wiki_sync_status"
  fi
done < <(find "$artifacts_dir" -mindepth 2 -maxdepth 2 -name meta.md | sort)

if [[ "$found" -eq 0 ]]; then
  echo "pending wiki sync 없음"
fi
