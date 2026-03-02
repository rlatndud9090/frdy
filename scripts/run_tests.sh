#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if command -v lua >/dev/null 2>&1; then
  LUA_BIN="lua"
elif command -v luajit >/dev/null 2>&1; then
  LUA_BIN="luajit"
else
  echo "lua/luajit 실행 파일을 찾을 수 없습니다." >&2
  exit 127
fi

"$ROOT_DIR/scripts/check_rng_usage.sh"
"$LUA_BIN" "$ROOT_DIR/tests/run.lua"
