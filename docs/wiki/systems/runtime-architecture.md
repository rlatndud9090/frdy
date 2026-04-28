# Runtime Architecture

이 문서는 현재 코드 구현 기준의 게임 구조와 시스템을 정리합니다.

## 1. 핵심 판타지

- 플레이어는 마왕이지만, 들키지 않게 용사의 생존/성장을 유도해야 합니다.
- 조력은 유리하지만 의심 수치를 올리고, 의심 누적은 게임 오버 위험으로 이어집니다.
- 핵심 재미는 "직접 싸우는 것"보다 "예측된 전투 흐름에 개입하는 것"에 있습니다.

## 2. 장르/플레이 구조

- 장르: 턴 기반 전투 + 노드 진행 + 개입 전략 중심 로그라이트
- 전투 전개: Planning(계획) → Execution(실행) 2페이즈 반복
- 메타 성장: 전투/이벤트/정산 보상을 통해 주문/패턴/전설 아이템을 확장

## 3. 런타임 아키텍처

### 3.1 진입 구조

- Love2D 엔트리: `main.lua`
- 게임 싱글턴: `src/core/game.lua`
- 씬 관리: `src/core/scene_manager.lua`
- 진입 씬: `src/scene/main_menu_scene.lua`
- 현재 기본 플레이 씬: `src/scene/game_scene.lua`
- 런 종료 씬: `src/scene/run_end_scene.lua`

### 3.2 GameScene 페이즈

- `START_NODE_SELECT`
- `TRAVELING`
- `ARRIVING`
- `ENTERING_COMBAT` / `COMBAT` / `EXITING_COMBAT`
- `ENTERING_EVENT` / `EVENT` / `EXITING_EVENT`
- `SETTLEMENT`
- `EDGE_SELECT`

### 3.3 런 저장 / 이어하기

- 진행 중 런은 active save 1개를 기준으로 유지합니다.
- 저장은 `RunSaveCoordinator`, `RunSave`, participant registry 기반으로 관리합니다.
- 저장 포맷은 data-only 구조를 사용하며, validator/sanitizer 계층을 통해 복원 안전성을 높입니다.
- 대표 체크포인트:
  - `start_node_select`
  - `combat_start`
  - `event_start`
  - `reward_offer_presented`
  - `path_ready`
  - `travel_start`
  - `floor_transition_pending`
- 메인 메뉴의 `이어하기`는 active save 존재 여부에 따라 노출됩니다.
- 용사 사망 또는 명시적 포기 시 active save를 정리하고 `RunEndScene`으로 전환합니다.

## 4. 핵심 시스템

### 4.1 맵 시스템

- 노드-엣지 그래프: `Map` / `Floor` / `Node` / `Edge`
- 노드 타입: `CombatNode`, `EventNode`
- 생성기: `MapGenerator`
- 시작 노드 선택 후, 간선 선택으로 다음 노드 진행

### 4.2 전투 + 예측 타임라인 시스템

- 핵심 도메인: `CombatManager`, `TurnManager`, `TimelineManager`, `PredictionEngine`
- 전투 엔티티: `Hero`, `Enemy`, `ActionPattern`
- 상태 효과: `StatusContainer`, `StatusRegistry`

`StatusContainer` 유지보수 불변식:

- `emit()`은 snapshot 순회와 생존 인덱스를 함께 사용해, 순회 도중 제거된 상태 hook를 다시 호출하지 않아야 합니다.
- UID가 hook 중 바뀔 수 있으므로 `_status_by_uid`는 stale alias를 남기지 않게 재매핑되어야 합니다.
- `restore()`는 상태 목록뿐 아니라 UID 인덱스, 생존 인덱스, 다음 UID까지 함께 재구축해야 합니다.

흐름:

1. Planning phase에서 주문/개입 계획 수립
2. Timeline 예측값 확인
3. Execution phase에서 예측 행동 순차 실행
4. 턴 종료 후 다음 Planning으로 복귀

### 4.3 주문(개입) 시스템

- 카드/덱 구조가 아니라 `SpellBook/Spell` 구조를 사용합니다.
- 주요 타입:
  - `SpellBook`
  - `Spell`
  - `SpellEffect`
- 대상 모드:
  - `char_single`
  - `char_faction`
  - `char_all`
  - `action_next_n`, `action_next_all`, `field`

현재 규칙:

- 전투용 타깃 스펠은 스펠별 진영 제한을 두지 않습니다.
- 용사 쪽을 고르면 의심이 감소하고, 적 쪽을 고르면 의심이 증가합니다.
- `char_all` 스펠은 기본적으로 의심치를 발생시키지 않습니다.

### 4.4 보상/성장 시스템

- 정산 관리자: `RewardManager`
- 각성 루프: `DemonAwakening`
- 전설 아이템 인벤토리: `LegendaryInventory`
- 보상 큐 기반으로 `SETTLEMENT` 페이즈에서 선택/적용

### 4.5 이벤트/경로 선택 시스템

- 이벤트: `EventManager`, `Event`, `Choice`, `EventHandler`
- 경로 선택: `EdgeSelectHandler`, `EdgeSelector`
- 경로/이벤트/보상 선택에는 자동 확정 타이머를 두지 않습니다.

### 4.6 의심/마나 시스템

- 의심: `SuspicionManager`
- 마나: `ManaManager`
- 이득과 의심 리스크를 동시에 관리하는 것이 핵심 전략입니다.
- `SuspicionManager`는 의심 수치가 최대치에 도달하면 `suspicion_max` 이벤트를 발행합니다.
- `GameScene`은 런타임 이벤트 버스의 `suspicion_max`를 구독해 `detected` 사유의 `RunEndScene` 종료로 연결합니다.
- `GameScene:exit()`와 런 종료 경로는 이 구독을 해제해, 씬 교체 뒤 종료 이벤트가 중복 처리되지 않게 합니다.
- 이벤트 치사, 전투 패배, 의심 최대치 종료는 active save 정리 후 `RunEndScene`으로 넘어가는 공통 종료 경계를 공유합니다.

### 4.7 결정론 RNG 시스템

- `RunContext` + 스트림 RNG(`RNG`) 사용
- 맵/적 생성/이벤트/보상/선택/UI 흔들림까지 스트림 분리
- `FRDY_RUN_SEED` 환경변수로 런 시드 고정 가능

## 5. UI/UX 원칙

- 핵심 HUD: 의심/마나/용사 상태/미니맵
- 전투 시 `SpellBookOverlay` + `TimelineUI`로 개입/확정
- 맵은 `Minimap` + `MapOverlay` 조합
- 메인 메뉴는 `이어하기/새 게임/설정` 중심 진입 구조를 가집니다.
- 절대 원칙:
  - 자동 확정 금지
  - 시간 압박 UX 금지

## 6. 데이터 중심 설계

- 주문 데이터: `data/spells/*.lua`
- 이벤트 데이터: `data/events/*.lua`
- 적 데이터: `data/enemies/*.lua`
- 보상/전설/상태: `data/rewards/*.lua`, `data/statuses/*.lua`
- 맵 설정: `data/map_configs/*.lua`

## 7. 보완 과제

- save/continue UX는 보강되었지만, 컬렉션/통계/메타 화면은 아직 확장 여지가 있습니다.

## 출처

- 루트 호환성 포인터: [`../../../GAME_CONCEPT.md`](../../../GAME_CONCEPT.md)
