#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

branch="${GITHUB_HEAD_REF:-$(git branch --show-current)}"
issue=""
summary=""
scope_in=""
scope_out=""
constraints=""
acceptance=""
notes=""
force=0
wiki_targets=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --branch)
      branch="$2"
      shift 2
      ;;
    --issue)
      issue="$2"
      shift 2
      ;;
    --summary)
      summary="$2"
      shift 2
      ;;
    --scope-in)
      scope_in="$2"
      shift 2
      ;;
    --scope-out)
      scope_out="$2"
      shift 2
      ;;
    --constraints)
      constraints="$2"
      shift 2
      ;;
    --acceptance)
      acceptance="$2"
      shift 2
      ;;
    --notes)
      notes="$2"
      shift 2
      ;;
    --wiki-target)
      wiki_targets+=("$2")
      shift 2
      ;;
    --force)
      force=1
      shift
      ;;
    *)
      echo "알 수 없는 옵션: $1" >&2
      exit 1
      ;;
  esac
done

if [[ -z "$branch" || "$branch" == "main" ]]; then
  echo "start_work_unit은 main이 아닌 작업 브랜치에서 실행해야 합니다." >&2
  exit 1
fi

if [[ "$branch" != "$(git branch --show-current)" ]]; then
  echo "현재 브랜치와 --branch 값이 다릅니다. 먼저 대상 브랜치로 switch 하세요." >&2
  exit 1
fi

if [[ -z "$summary" || ${#summary} -lt 10 ]]; then
  echo "--summary는 10자 이상으로 입력해야 합니다." >&2
  exit 1
fi

work_unit_id="$(printf "%s" "$branch" | tr '/[:upper:]' '-[:lower:]' | sed 's/[^a-z0-9._-]/-/g')"
artifact_dir="$("$ROOT_DIR/scripts/ensure_artifact_scaffold.sh" "$branch")"
meta_path="$artifact_dir/meta.md"
prd_path="$artifact_dir/prd.md"
timeline_path="$artifact_dir/timeline.md"

if [[ "$force" -ne 1 ]] && ! grep -q "이 작업 단위의 목표를 1~3줄로 적습니다." "$meta_path"; then
  echo "이미 채워진 artifact가 있습니다. 덮어쓰려면 --force를 사용하세요." >&2
  exit 1
fi

today="$(date +%F)"
timestamp="$(date '+%F %H:%M')"
issue_ref=""
if [[ -n "$issue" ]]; then
  issue_ref="$issue"
  if [[ "$issue_ref" != \#* ]]; then
    issue_ref="#$issue_ref"
  fi
fi

if [[ -z "$scope_in" ]]; then
  scope_in="$summary"
fi
if [[ -z "$scope_out" ]]; then
  scope_out="현재 작업 목적과 직접 관련 없는 주변 정리, 별도 기능 확장, 후속 이슈 범위"
fi
if [[ -z "$constraints" ]]; then
  constraints="기존 artifact/wiki 운영 규칙과 CI 흐름을 깨지 않는 선에서 최소 범위로 정리합니다."
fi
if [[ -z "$acceptance" ]]; then
  acceptance="$summary"
fi
if [[ -z "$notes" ]]; then
  notes="브랜치 시작 직후 artifact 초안을 채워 껍데기 상태로 작업이 진행되지 않게 합니다."
fi

{
  printf '%s\n' '---'
  printf 'id: %s\n' "$work_unit_id"
  printf 'branch: %s\n' "$branch"
  printf '%s\n' 'status: in_progress'
  printf '%s\n' 'wiki_sync_status: pending'
  printf 'created_at: %s\n' "$today"
  printf 'updated_at: %s\n' "$today"
  printf 'related_issue: %s\n' "$issue_ref"
  printf '%s\n' 'related_pr:'
  printf '%s\n' 'merge_commit:'
  printf '%s\n' 'wiki_targets:'
  if [[ "${#wiki_targets[@]}" -eq 0 ]]; then
    printf '%s\n' '  - docs/wiki/project/overview.md'
  else
    for target in "${wiki_targets[@]}"; do
      printf '  - %s\n' "$target"
    done
  fi
  printf '%s\n\n' '---'
  printf '%s\n\n' '# Work Unit Meta'
  printf '%s\n\n' '## Goal'
  printf -- '- %s\n' "$summary"
  printf -- '- 이 브랜치의 변경과 검증 결과를 artifact에 지속적으로 누적합니다.\n\n'
  printf '%s\n\n' '## Scope'
  printf -- '- 포함 범위: %s\n' "$scope_in"
  printf -- '- 제외 범위: %s\n\n' "$scope_out"
  printf '%s\n\n' '## Acceptance'
  printf -- '- %s\n' "$acceptance"
  printf -- '- PR 전 `./scripts/check_artifact_progress.sh`와 `./scripts/check_artifact_guard.sh`를 통과합니다.\n\n'
  printf '%s\n\n' '## Notes'
  printf -- '- %s\n' "$notes"
} > "$meta_path"

{
  printf '%s\n\n' '# PRD'
  printf -- '- work-unit: %s\n' "$work_unit_id"
  printf -- '- branch: %s\n\n' "$branch"
  printf '%s\n\n' '## Problem'
  printf -- '- %s\n\n' "$summary"
  printf '%s\n\n' '## Goal'
  printf -- '- %s\n\n' "$summary"
  printf '%s\n\n' '## Constraints'
  printf -- '- %s\n\n' "$constraints"
  printf '%s\n\n' '## Acceptance'
  printf -- '- %s\n' "$acceptance"
} > "$prd_path"

{
  printf '%s\n\n' '# Timeline'
  printf -- '- %s | 작업 시작 및 artifact 초기화\n' "$timestamp"
  printf -- '- %s | 작업 요약 확정: %s\n' "$timestamp" "$summary"
} > "$timeline_path"

"$ROOT_DIR/scripts/check_artifact_progress.sh" "$branch"
echo "$artifact_dir"
