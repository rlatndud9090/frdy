#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

BASE_REF="${1:-${GITHUB_EVENT_BEFORE:-HEAD~1}}"
HEAD_REF="${2:-HEAD}"

if ! git rev-parse --verify "$BASE_REF" >/dev/null 2>&1; then
  echo "기준 커밋($BASE_REF)을 찾지 못해 main artifact audit를 건너뜁니다."
  exit 0
fi

changed_files="$(git diff --name-only "${BASE_REF}..${HEAD_REF}")"
if [[ -z "$changed_files" ]]; then
  echo "변경 파일이 없어 main artifact audit를 건너뜁니다."
  exit 0
fi

meaningful_changed="$(printf "%s\n" "$changed_files" \
  | grep -Ev '^(docs/artifacts/|\.gitignore$)' || true)"

mapfile -t artifact_dirs < <(
  printf "%s\n" "$changed_files" \
    | grep -E '^docs/artifacts/[^/]+/' \
    | grep -Ev '^docs/artifacts/_template/' \
    | awk -F/ '{print $1 "/" $2 "/" $3}' \
    | sort -u
)

if [[ -n "$meaningful_changed" && "${#artifact_dirs[@]}" -eq 0 ]]; then
  echo "실패: main에 반영된 변경 중 artifact 갱신이 없는 항목이 있습니다." >&2
  echo "--- 변경 파일 ---" >&2
  printf "%s\n" "$meaningful_changed" >&2
  echo "---------------" >&2
  exit 1
fi

if [[ "${#artifact_dirs[@]}" -eq 0 ]]; then
  echo "artifact 변경이 없어 main artifact audit를 통과합니다."
  exit 0
fi

for artifact_dir in "${artifact_dirs[@]}"; do
  work_unit_id="$(basename "$artifact_dir")"
  python3 "$ROOT_DIR/scripts/check_artifact_completeness.py" \
    --artifact-dir "$ROOT_DIR/$artifact_dir" \
    --mode main-audit \
    --expected-id "$work_unit_id"
done

echo "main artifact audit 통과"
