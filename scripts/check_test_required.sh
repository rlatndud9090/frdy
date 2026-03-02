#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

BASE_REF="${1:-origin/main}"
if ! git rev-parse --verify "$BASE_REF" >/dev/null 2>&1; then
  echo "기준 브랜치($BASE_REF)를 찾지 못해 테스트-필수 체크를 건너뜁니다."
  exit 0
fi

changed_files="$(git diff --name-only "${BASE_REF}...HEAD")"
if [[ -z "$changed_files" ]]; then
  echo "변경 파일이 없어 테스트-필수 체크를 건너뜁니다."
  exit 0
fi

code_changed="$(printf "%s\n" "$changed_files" \
  | grep -E '^(src|data)/.+\.lua$' \
  | grep -Ev '^src/i18n/locales/' || true)"
test_changed="$(printf "%s\n" "$changed_files" | grep -E '^tests/.+_test\.lua$' || true)"

if [[ -n "$code_changed" && -z "$test_changed" ]]; then
  echo "실패: src/data Lua 코드 변경이 있지만 tests/*_test.lua 변경이 없습니다." >&2
  echo "--- 코드 변경 파일 ---" >&2
  printf "%s\n" "$code_changed" >&2
  echo "---------------------" >&2
  exit 1
fi

echo "테스트-필수 체크 통과"
