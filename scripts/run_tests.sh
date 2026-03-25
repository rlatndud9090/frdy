#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$ROOT_DIR/scripts/automation_run_seed.sh"

if command -v lua >/dev/null 2>&1; then
  LUA_BIN="lua"
elif command -v luajit >/dev/null 2>&1; then
  LUA_BIN="luajit"
else
  echo "lua/luajit 실행 파일을 찾을 수 없습니다." >&2
  exit 127
fi

"$ROOT_DIR/scripts/check_rng_usage.sh"
bash "$ROOT_DIR/tests/scripts/automation_run_seed_test.sh"
frdy_run_with_automation_run_seed "$LUA_BIN" "$ROOT_DIR/tests/run.lua"
