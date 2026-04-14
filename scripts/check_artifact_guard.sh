#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

BASE_REF="${1:-origin/main}"
if ! git rev-parse --verify "$BASE_REF" >/dev/null 2>&1; then
  echo "기준 브랜치($BASE_REF)를 찾지 못해 artifact guard를 건너뜁니다."
  exit 0
fi

branch="$(git branch --show-current)"
if [[ -z "$branch" || "$branch" == "main" ]]; then
  echo "main 또는 detached 상태에서는 artifact guard를 건너뜁니다."
  exit 0
fi

changed_files="$(git diff --name-only "${BASE_REF}...HEAD")"
if [[ -z "$changed_files" ]]; then
  echo "변경 파일이 없어 artifact guard를 건너뜁니다."
  exit 0
fi

meaningful_changed="$(printf "%s\n" "$changed_files" \
  | grep -E '^(src|data|assets|tests)/' || true)"

if [[ -z "$meaningful_changed" ]]; then
  echo "코드/데이터/테스트 변경이 없어 artifact guard를 건너뜁니다."
  exit 0
fi

work_unit_id="$(printf "%s" "$branch" | tr '/[:upper:]' '-[:lower:]' | sed 's/[^a-z0-9._-]/-/g')"
artifact_dir="$ROOT_DIR/docs/artifacts/$work_unit_id"
meta_file="$artifact_dir/meta.md"

if [[ ! -f "$meta_file" ]]; then
  echo "실패: 코드/데이터 변경이 있지만 작업 단위 artifact가 없습니다." >&2
  echo "브랜치: $branch" >&2
  echo "예상 경로: $artifact_dir" >&2
  echo "먼저 ./scripts/ensure_artifact_scaffold.sh 를 실행하세요." >&2
  exit 1
fi

if ! grep -q '^wiki_sync_status:' "$meta_file"; then
  echo "실패: $meta_file 에 wiki_sync_status가 없습니다." >&2
  exit 1
fi

if ! grep -q '^status:' "$meta_file"; then
  echo "실패: $meta_file 에 status가 없습니다." >&2
  exit 1
fi

echo "artifact guard 통과"
