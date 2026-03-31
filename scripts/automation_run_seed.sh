#!/usr/bin/env bash

FRDY_AUTOMATION_DEFAULT_RUN_SEED="424242"

frdy_resolve_automation_run_seed() {
  local raw_seed="${FRDY_RUN_SEED-}"
  if [[ -z "$raw_seed" ]]; then
    printf '%s\n' "$FRDY_AUTOMATION_DEFAULT_RUN_SEED"
    return 0
  fi

  printf '%s\n' "$raw_seed"
}

frdy_run_with_automation_run_seed() {
  local resolved_seed
  resolved_seed="$(frdy_resolve_automation_run_seed)"
  FRDY_RUN_SEED="$resolved_seed" "$@"
}
