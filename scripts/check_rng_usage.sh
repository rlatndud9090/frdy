#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

TARGETS=(
  "$ROOT_DIR/src/map"
  "$ROOT_DIR/src/reward"
  "$ROOT_DIR/src/event"
  "$ROOT_DIR/src/handler"
  "$ROOT_DIR/src/scene"
)

if rg -n "math\\.random(seed)?\\s*\\(" "${TARGETS[@]}"; then
  echo ""
  echo "gameplay 경로에서 전역 math.random/math.randomseed 직접 호출이 감지되었습니다." >&2
  echo "RNG 서비스를 통해 난수를 사용하세요." >&2
  exit 1
fi

echo "[OK] gameplay RNG direct calls: 0"
