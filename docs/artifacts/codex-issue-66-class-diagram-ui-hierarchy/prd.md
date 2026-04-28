# PRD

- work-unit: codex-issue-66-class-diagram-ui-hierarchy
- branch: codex/issue-66-class-diagram-ui-hierarchy

## Problem

- `docs/wiki/systems/class-architecture.md`의 UI 계층 다이어그램이 `MapOverlay`와 `SettingsOverlay`를 `UIElement` 상속 계층처럼 오해하게 만들 수 있었습니다.
- 실제 코드는 `MapOverlay`와 `SettingsOverlay`를 독립 overlay 객체로 구성하고, `GameScene`이 composition으로 보유합니다.

## Goal

- UI 계층 다이어그램을 현재 코드 기준으로 정정합니다.
- `MapOverlay`, `SettingsOverlay`는 `UIElement` 하위 클래스가 아니라 `GameScene`이 직접 사용하는 overlay 객체로 표현합니다.

## Constraints

- 런타임 UI 리팩터링 없이 문서만 현재 코드와 맞춥니다.
- `TimelineUI`, `SpellBookOverlay`, `EdgeSelector`, `Minimap`처럼 실제 `UIElement`를 상속하는 위젯 관계는 유지합니다.
- 위키는 main 반영 후 현재형으로 재합성합니다.

## Acceptance

- `MapOverlay`, `SettingsOverlay`가 `UIElement` 상속 화살표 없이 표시됩니다.
- `GameScene --> MapOverlay`, `GameScene --> SettingsOverlay` composition 관계는 남습니다.
- `docs/wiki/systems/class-architecture.md`가 현재 코드의 UI 계층을 설명합니다.
