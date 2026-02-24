#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if command -v timeout >/dev/null 2>&1; then
  TIMEOUT_BIN="timeout"
elif command -v gtimeout >/dev/null 2>&1; then
  TIMEOUT_BIN="gtimeout"
else
  echo "timeout/gtimeout 명령을 찾을 수 없습니다." >&2
  exit 127
fi

TMP_LOG="$(mktemp)"
FILTERED_LOG="$(mktemp)"
trap 'rm -f "$TMP_LOG" "$FILTERED_LOG"' EXIT

set +e
FRDY_CI_CHECK=1 "$TIMEOUT_BIN" 5 love "$ROOT_DIR" >"$TMP_LOG" 2>&1
status=$?
set -e

# macOS 입력기 초기화 로그는 검증 에러가 아니므로 제외.
sed '/IMKClient subclass/d; /IMKInputSession subclass/d' "$TMP_LOG" >"$FILTERED_LOG"

# 검증 규칙: 5초 타임아웃(124) + 출력 없음 => 정상
if [[ $status -eq 124 ]]; then
  if [[ -s "$FILTERED_LOG" ]]; then
    cat "$FILTERED_LOG" >&2
    exit 1
  fi
  exit 0
fi

if [[ -s "$FILTERED_LOG" ]]; then
  cat "$FILTERED_LOG" >&2
fi
exit "$status"
