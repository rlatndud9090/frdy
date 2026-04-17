#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

BASE_REF="${1:-origin/main}"
if ! git rev-parse --verify "$BASE_REF" >/dev/null 2>&1; then
  echo "기준 브랜치($BASE_REF)를 찾지 못해 artifact guard를 건너뜁니다."
  exit 0
fi

head_ref="${GITHUB_HEAD_REF:-}"
branch="${head_ref:-$(git branch --show-current)}"
if [[ -z "$branch" ]]; then
  echo "artifact guard를 수행할 작업 브랜치를 확인할 수 없습니다." >&2
  exit 0
fi
if [[ -z "$head_ref" && "$branch" == "main" ]]; then
  echo "로컬 main에서는 artifact guard를 건너뜁니다." >&2
  exit 0
fi

changed_files="$(git diff --name-only "${BASE_REF}...HEAD")"
if [[ -z "$changed_files" ]]; then
  echo "변경 파일이 없어 artifact guard를 건너뜁니다."
  exit 0
fi

work_unit_id="$(printf "%s" "$branch" | tr '/[:upper:]' '-[:lower:]' | sed 's/[^a-z0-9._-]/-/g')"
artifact_dir="$ROOT_DIR/docs/artifacts/$work_unit_id"
changed_artifact_dirs="$(
  printf "%s\n" "$changed_files" \
    | grep -E '^docs/artifacts/[^/]+/' \
    | grep -Ev '^docs/artifacts/_template/' \
    | awk -F/ '{print $1 "/" $2 "/" $3}' \
    | sort -u || true
)"

python3 "$ROOT_DIR/scripts/check_artifact_completeness.py" \
  --artifact-dir "$artifact_dir" \
  --mode pr \
  --expected-id "$work_unit_id" \
  --expected-branch "$branch"

while IFS= read -r changed_artifact_dir; do
  [[ -z "$changed_artifact_dir" ]] && continue
  if [[ "$ROOT_DIR/$changed_artifact_dir" == "$artifact_dir" ]]; then
    continue
  fi
  python3 "$ROOT_DIR/scripts/check_artifact_completeness.py" \
    --artifact-dir "$ROOT_DIR/$changed_artifact_dir" \
    --mode main-audit \
    --expected-id "$(basename "$changed_artifact_dir")"
done <<< "$changed_artifact_dirs"

echo "artifact guard 통과"
