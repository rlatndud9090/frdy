#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$ROOT_DIR/scripts/automation_run_seed.sh"

assert_eq() {
  local expected="$1"
  local actual="$2"
  local message="$3"
  if [[ "$expected" != "$actual" ]]; then
    echo "automation_run_seed_test: $message (expected '$expected', got '$actual')" >&2
    exit 1
  fi
}

run_check_love_basic_path_test() {
  local temp_dir
  temp_dir="$(mktemp -d)"
  trap 'rm -rf "$temp_dir"' RETURN

  cat >"$temp_dir/timeout" <<'EOF'
#!/usr/bin/env bash
shift
"$@"
EOF
  cat >"$temp_dir/love" <<'EOF'
#!/usr/bin/env bash
printf '%s' "${FRDY_RUN_SEED-}" >"${FRDY_AUTOMATION_TEST_LOVE_OUT:?}"
exit 124
EOF
  chmod +x "$temp_dir/timeout" "$temp_dir/love"

  PATH="$temp_dir:$PATH" FRDY_AUTOMATION_TEST_LOVE_OUT="$temp_dir/love_seed.txt" \
    bash "$ROOT_DIR/scripts/check_love.sh"

  local resolved_seed
  resolved_seed="$(cat "$temp_dir/love_seed.txt")"
  assert_eq "$FRDY_AUTOMATION_DEFAULT_RUN_SEED" "$resolved_seed" "check_love 기본 경로는 기본 seed를 주입해야 합니다"
}

run_check_love_fallback_path_test() {
  local temp_dir
  temp_dir="$(mktemp -d)"
  trap 'rm -rf "$temp_dir"' RETURN

  cat >"$temp_dir/timeout" <<'EOF'
#!/usr/bin/env bash
shift
"$@"
EOF
  cat >"$temp_dir/love" <<'EOF'
#!/usr/bin/env bash
echo "No available video device" >&2
exit 1
EOF
  cat >"$temp_dir/lua" <<'EOF'
#!/usr/bin/env bash
printf '%s' "${FRDY_RUN_SEED-}" >"${FRDY_AUTOMATION_TEST_LUA_OUT:?}"
exit 0
EOF
  chmod +x "$temp_dir/timeout" "$temp_dir/love" "$temp_dir/lua"

  PATH="$temp_dir:$PATH" FRDY_RUN_SEED="123" FRDY_AUTOMATION_TEST_LUA_OUT="$temp_dir/lua_seed.txt" \
    bash "$ROOT_DIR/scripts/check_love.sh"

  local resolved_seed
  resolved_seed="$(cat "$temp_dir/lua_seed.txt")"
  assert_eq "123" "$resolved_seed" "check_love fallback 경로는 숫자형 override를 보존해야 합니다"
}

unset FRDY_RUN_SEED || true
assert_eq "$FRDY_AUTOMATION_DEFAULT_RUN_SEED" "$(frdy_resolve_automation_run_seed)" "unset seed는 기본값이어야 합니다"

FRDY_RUN_SEED=""
assert_eq "$FRDY_AUTOMATION_DEFAULT_RUN_SEED" "$(frdy_resolve_automation_run_seed)" "empty seed는 기본값이어야 합니다"

FRDY_RUN_SEED="777"
assert_eq "777" "$(frdy_resolve_automation_run_seed)" "명시적 override는 그대로 전달되어야 합니다"

FRDY_RUN_SEED="nonnumeric"
assert_eq "nonnumeric" "$(frdy_resolve_automation_run_seed)" "non-empty override는 helper가 그대로 전달해야 합니다"

unset FRDY_RUN_SEED || true
run_check_love_basic_path_test
run_check_love_fallback_path_test
