---
id: codex-issue-66-class-diagram-ui-hierarchy
branch: codex/issue-66-class-diagram-ui-hierarchy
status: in_progress
wiki_sync_status: pending
created_at: 2026-04-15
updated_at: 2026-04-15
related_issue: "#66"
related_pr: "#70"
merge_commit:
wiki_targets:
  - docs/wiki/systems/class-architecture.md
---

# Work Unit Meta

## Goal

- UI 계층 다이어그램을 현재 코드 기준으로 정정합니다.
- `MapOverlay`, `SettingsOverlay`가 `UIElement` 상속으로 오해되지 않도록 위키를 맞춥니다.

## Scope

- 포함 범위: `docs/wiki/systems/class-architecture.md`의 UI 다이어그램 정정, 이슈/PR handoff 메타 유지
- 제외 범위: 런타임 UI 클래스 리팩터링, 다른 stale 이슈 정리, main 머지 후 wiki sync 확정 처리

## Acceptance

- `MapOverlay`, `SettingsOverlay`가 위키 다이어그램에서 `UIElement` 하위 클래스로 표기되지 않습니다.
- artifact `status`, `wiki_sync_status`, 이슈/PR 연계 정보가 작업 중에도 유지됩니다.
- PR 생성 전 필수 검증과 artifact guard를 통과합니다.

## Notes

- 이슈 본문은 루트 `CLASS_DIAGRAM.md`를 언급하지만, 현재 워크트리의 실제 불일치는 위키 문서에 남아 있었습니다.
- main 머지 후 위키 sync가 끝나면 `wiki_sync_status: synced`로 후속 갱신합니다.
