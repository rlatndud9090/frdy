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
HEADLESS_LOG="$(mktemp)"
trap 'rm -f "$TMP_LOG" "$FILTERED_LOG" "$HEADLESS_LOG"' EXIT

resolve_lua_bin() {
  if command -v lua >/dev/null 2>&1; then
    echo "lua"
    return 0
  fi

  if command -v luajit >/dev/null 2>&1; then
    echo "luajit"
    return 0
  fi

  echo "lua/luajit 실행 파일을 찾을 수 없습니다." >&2
  return 127
}

is_headless_display_failure() {
  local log_file="$1"
  local pattern="Could not initialize SDL video subsystem|Could not set window mode|The video driver did not add any displays|Unable to create OpenGL window"
  grep -Eq "$pattern" "$log_file"
}

run_headless_smoke_check() {
  local lua_bin
  lua_bin="$(resolve_lua_bin)" || return $?
  FRDY_CI_CHECK=1 "$lua_bin" "$ROOT_DIR/scripts/check_love_headless.lua"
}

set +e
FRDY_CI_CHECK=1 "$TIMEOUT_BIN" 5 love "$ROOT_DIR" >"$TMP_LOG" 2>&1
status=$?
set -e

# macOS 입력기 초기화 로그는 검증 에러가 아니므로 제외.
sed '/IMKClient subclass/d; /IMKInputSession subclass/d' "$TMP_LOG" >"$FILTERED_LOG"

if [[ $status -eq 124 && ! -s "$FILTERED_LOG" ]]; then
  exit 0
fi

if [[ -s "$FILTERED_LOG" ]] && is_headless_display_failure "$FILTERED_LOG"; then
  if run_headless_smoke_check >"$HEADLESS_LOG" 2>&1; then
    exit 0
  fi

  cat "$FILTERED_LOG" >&2
  if [[ -s "$HEADLESS_LOG" ]]; then
    cat "$HEADLESS_LOG" >&2
  fi
  exit 1
fi

if [[ -s "$FILTERED_LOG" ]]; then
  cat "$FILTERED_LOG" >&2
fi

exit "$status"
