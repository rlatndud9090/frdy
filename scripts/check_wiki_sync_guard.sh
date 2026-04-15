#!/usr/bin/env bash
set -euo pipefail

# main 트리 안에 존재하는 artifact 중 wiki_sync_status가 pending이면
# 별도의 status 값과 무관하게 wiki sync 후보로 간주합니다.
# artifact가 이미 main에 존재한다는 사실 자체가 "머지 후 상태"의 근거입니다.

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
  if [[ "$work_unit_id" == "_template" ]]; then
    continue
  fi
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
