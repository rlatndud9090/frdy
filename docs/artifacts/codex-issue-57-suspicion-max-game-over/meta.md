---
id: codex-issue-57-suspicion-max-game-over
branch: codex/issue-57-suspicion-max-game-over
status: in_progress
wiki_sync_status: pending
created_at: 2026-04-15
updated_at: 2026-04-15
related_issue: "#57"
related_pr: "#69"
merge_commit:
wiki_targets: []
---

# Work Unit Meta

## Goal

- PR #69를 최신 `main`에 재정렬하고 남아 있던 Codex 리뷰 지적을 반영합니다.
- `suspicion_max` 런타임 구독이 씬 교체 시 누수되지 않도록 안전하게 정리합니다.

## Scope

- 포함 범위: `src/scene/game_scene.lua` 충돌 해결, 런타임 이벤트 구독 해제 보강, 관련 테스트 갱신
- 제외 범위: PR #69와 무관한 다른 이슈 처리, wiki 본문 갱신 강제, 별도 기능 확장

## Acceptance

- PR #69가 `origin/main`과 충돌 없이 정리됩니다.
- `GameScene`이 씬 종료 시 `suspicion_max` 구독을 해제합니다.
- 관련 테스트와 Love 검증이 통과하고, 리뷰 코멘트에 반영 내용을 답글로 남깁니다.

## Notes

- 현재 `main`은 이미 `detected` 사유의 `RunEndScene` 종료 흐름을 사용하므로, 그 동작을 유지한 채 리뷰 지적만 추가 보강합니다.
- 위키 동기화는 이번 수정이 내부 안전장치 성격이라 우선 후속 판단으로 둡니다.
