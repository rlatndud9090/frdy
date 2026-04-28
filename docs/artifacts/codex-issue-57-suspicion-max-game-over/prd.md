# PRD

- work-unit: codex-issue-57-suspicion-max-game-over
- branch: codex/issue-57-suspicion-max-game-over

## Problem

- `suspicion_max`가 발생해도 씬 전환/런 종료 경계에서 런타임 이벤트 구독이 남으면, 종료 이후 같은 이벤트가 다시 처리되거나 테스트가 누수 경로를 놓칠 수 있습니다.
- 이벤트 치사 피해와 전투 패배도 같은 런 종료 흐름을 거쳐야 active save 정리와 `RunEndScene` 표시가 일관됩니다.

## Goal

- `GameScene`이 `suspicion_max` 이벤트를 구독하고, 씬 종료 또는 런 종료 시 반드시 해제합니다.
- 의심 최대치 도달은 `detected` 사유의 `RunEndScene` 종료로 통일합니다.
- 이벤트 치사/전투 패배/의심 최대치 종료 경로를 회귀 테스트로 고정합니다.

## Constraints

- 이미 main에 존재하는 `detected` 종료 사유와 active save 정리 흐름을 보존합니다.
- PR #69의 리뷰 지적 범위 안에서 구독 생명주기와 테스트만 보강합니다.
- 위키는 main 반영 후 현재형으로 재합성합니다.

## Acceptance

- `GameScene:exit()`와 런 종료 경로가 `suspicion_max` 구독을 해제합니다.
- `suspicion_max`는 중복 처리되지 않고 `detected` 사유로 런을 종료합니다.
- 관련 단위 테스트와 Love smoke 검증이 통과합니다.
- `docs/wiki/systems/runtime-architecture.md`와 구현 히스토리가 main 기준 현재 상태를 설명합니다.
