# FRDY Project Overview

## 핵심 판타지

- 플레이어는 마왕이지만, 들키지 않게 용사의 생존과 성장을 유도해야 합니다.
- 직접 전투를 수행하는 대신 전투 흐름을 예측하고 개입하는 조력자 역할이 핵심입니다.
- 조력은 유리하지만 의심 수치를 올리고, 의심 누적은 게임 오버로 이어질 수 있습니다.

## 장르와 루프

- 장르: 턴 기반 개입형 로그라이트
- 메인 루프: 맵 진행 → 전투/이벤트 → 정산/성장 → 다음 노드 선택
- 전투 루프: Planning → Execution 반복

## 런타임 구조

- 엔트리: `main.lua`
- 게임 싱글턴: `src/core/game.lua`
- 씬 관리: `src/core/scene_manager.lua`
- 진입 씬: `src/scene/main_menu_scene.lua`
- 기본 플레이 씬: `src/scene/game_scene.lua`
- 런 종료 씬: `src/scene/run_end_scene.lua`

`GameScene`은 아래 흐름을 통합 관리합니다.

- 시작 노드 선택
- 이동과 도착
- 전투 진입/실행/종료
- 이벤트 진입/선택/종료
- 정산과 보상 선택
- 다음 간선 선택

진행 중 런은 active save 1개를 기준으로 유지하며, 메인 메뉴의 `이어하기`와 런 종료 후 정리 흐름이 이 구조에 연결됩니다.

## 현재 운영 원칙

- 경로/이벤트/개입 선택에는 자동 확정 타이머를 두지 않습니다.
- 시간 압박 UX를 추가하지 않습니다.
- `docs/wiki/`가 현재형 지식층이며, 루트 문서는 호환성 포인터로만 유지합니다.
- `docs/artifacts/`는 작업 단위별 진실의 원천입니다.
- 작업 브랜치는 `./scripts/start_work_unit.sh`로 artifact 초안을 먼저 채우고 시작합니다.
- PR 전 artifact completeness guard와 main push audit가 템플릿-only artifact 머지를 차단합니다.
- 에이전트는 `wiki-first, artifacts-on-demand`로 조회합니다.

## 관련 문서

- [../systems/runtime-architecture.md](../systems/runtime-architecture.md)
- [../systems/class-architecture.md](../systems/class-architecture.md)
- [implementation-history.md](implementation-history.md)
- [../SCHEMA.md](../SCHEMA.md)
- [../RESOLVER.md](../RESOLVER.md)
