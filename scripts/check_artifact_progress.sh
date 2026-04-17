#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

branch="${1:-${GITHUB_HEAD_REF:-$(git branch --show-current)}}"
if [[ -z "$branch" || "$branch" == "main" ]]; then
  echo "현재 브랜치에서 artifact progress 검사를 수행할 수 없습니다." >&2
  exit 1
fi

work_unit_id="$(printf "%s" "$branch" | tr '/[:upper:]' '-[:lower:]' | sed 's/[^a-z0-9._-]/-/g')"
artifact_dir="$ROOT_DIR/docs/artifacts/$work_unit_id"

python3 "$ROOT_DIR/scripts/check_artifact_completeness.py" \
  --artifact-dir "$artifact_dir" \
  --mode progress \
  --expected-id "$work_unit_id" \
  --expected-branch "$branch"
