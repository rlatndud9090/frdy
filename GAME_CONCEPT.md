# 게임 컨셉: 마왕의 은밀한 조력

이 문서는 **현재 코드 구현 기준**의 게임 설계/흐름을 정리합니다.
과거 설계 초안(Deck/Card, MapScene/CombatScene 분리)을 기준으로 보지 않고,
`src/scene/game_scene.lua` 중심의 실제 런타임 구조를 기준으로 설명합니다.

## 1. 핵심 판타지

- 플레이어는 마왕이지만, 들키지 않게 용사의 생존/성장을 유도해야 합니다.
- 조력은 유리하지만 의심 수치를 올리고, 의심 누적은 게임 오버 위험으로 이어집니다.
- 핵심 재미는 "직접 싸우는 것"보다 "예측된 전투 흐름에 개입하는 것"에 있습니다.

## 2. 장르/플레이 구조

- 장르: 턴 기반 전투 + 노드 진행 + 개입 전략 중심 로그라이트
- 전투 전개: Planning(계획) → Execution(실행) 2페이즈 반복
- 메타 성장: 전투/이벤트/정산 보상을 통해 주문/패턴/전설 아이템을 확장

## 3. 런타임 아키텍처 (현재 구현)

### 3.1 진입 구조

- Love2D 엔트리: `main.lua`
- 게임 싱글턴: `src/core/game.lua`
- 씬 관리: `src/core/scene_manager.lua`
- 진입 씬: `MainMenuScene`
- 런타임 핵심 씬: **GameScene 단일 통합 구조** (`src/scene/game_scene.lua`)
- 런 종료 씬: `RunEndScene`

### 3.2 GameScene 페이즈

현재 GameScene은 아래 페이즈를 상태머신처럼 전환합니다.

- `START_NODE_SELECT`
- `TRAVELING`
- `ARRIVING`
- `ENTERING_COMBAT` / `COMBAT` / `EXITING_COMBAT`
- `ENTERING_EVENT` / `EVENT` / `EXITING_EVENT`
- `SETTLEMENT`
- `EDGE_SELECT`

### 3.3 런 저장 / 이어하기

- 진행 중 런은 active save 1개만 유지합니다.
- 세이브는 전투/이벤트/보상/경로 결정을 기준으로 한 **안전 체크포인트**에서만 갱신합니다.
- 저장 포맷은 실행 가능한 코드가 아니라 data-only 포맷을 사용하며, checksum/backup fallback으로 손상 복구 가능성을 높입니다.
- 저장 대상은 개별 시스템을 수동으로 나열하기보다 participant registry를 통해 수집/복원합니다.
- 현재 체크포인트:
  - `start_node_select`
  - `combat_start`
  - `event_start`
  - `reward_offer_presented`
  - `path_ready`
- `메인 화면`의 `이어하기`는 active save가 있을 때만 표시됩니다.
- 용사 사망 또는 명시적 포기 시 active save를 삭제하고 `RunEndScene`으로 전환합니다.

## 4. 핵심 시스템

### 4.1 맵 시스템

- 노드-엣지 그래프: `Map` / `Floor` / `Node` / `Edge`
- 노드 타입: `CombatNode`, `EventNode`
- 생성기: `MapGenerator` (`data/map_configs/default_config.lua` 기반)
- 시작 노드 선택 후, 간선 선택으로 다음 노드 진행

### 4.2 전투 + 예측 타임라인 시스템

전투 도메인:

- `CombatManager`, `TurnManager`, `TimelineManager`, `PredictionEngine`
- 전투 엔티티: `Hero`, `Enemy`, `ActionPattern`
- 상태효과: `StatusContainer`, `StatusRegistry`

핵심 흐름:

1. Planning phase에서 주문/개입 계획 수립
2. Timeline 예측값 확인
3. Execution phase에서 예측 행동 순차 실행
4. 턴 종료 후 다음 Planning으로 복귀

### 4.3 주문(개입) 시스템

- 카드/덱 구조가 아니라 **SpellBook/Spell** 구조를 사용합니다.
- 주요 타입:
  - `SpellBook`: 주문 보유/예약/확정
  - `Spell`: 비용, 대상 모드, 의심치, 효과
  - `SpellEffect`: 실제 적용 로직
- 대상 모드:
  - `char_single`: 용사 또는 적 한 명
  - `char_faction`: 용사 진영 전체 또는 적 진영 전체
  - `char_all`: 용사와 모든 적 전체
  - `action_next_n`, `action_next_all`, `field`
- 현재 전투용 타깃 스펠은 스펠별 진영 제한을 두지 않습니다.
  - `char_single`, `char_faction` 스펠은 항상 용사/적 양쪽을 대상으로 선택 가능합니다.
  - 의심치는 실제로 선택한 진영 기준으로 계산합니다.
  - 용사 쪽을 고르면 의심이 감소하고, 적 쪽을 고르면 의심이 증가합니다.
  - `char_all` 스펠은 진영 선택이 없고, 기본적으로 의심치를 발생시키지 않습니다.

참고:

- 내부 타임라인 조작 API(`swap/remove/delay/modify/global`)는 존재하지만,
  현재 기본 주문 데이터는 `insert` 중심으로 운용됩니다.

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
- 개입 효과의 이득과 의심 리스크를 동시 관리하는 것이 핵심 전략입니다.

### 4.7 결정론 RNG 시스템

- `RunContext` + 스트림 RNG(`RNG`) 사용
- 맵/적 생성/이벤트/보상/선택/UI 흔들림까지 스트림 분리
- `FRDY_RUN_SEED` 환경변수로 런 시드 고정 가능

## 5. UI/UX 원칙 (구현 반영)

- 핵심 HUD: 의심/마나/용사 상태/미니맵
- 전투 시 `SpellBookOverlay` + `TimelineUI`로 개입/확정
- 맵은 `Minimap` + `MapOverlay` 조합
- 메인 메뉴는 중앙 타이틀 + `이어하기/새 게임/설정/컬렉션/통계/게임 종료` 기본 구성을 사용합니다.
- 절대 원칙:
  - 경로/이벤트/개입 선택 자동 확정 금지
  - 시간 압박 UX(카운트다운/강제 진행) 금지

## 6. 데이터 중심 설계

- 주문 데이터: `data/spells/*.lua`
- 이벤트 데이터: `data/events/*.lua`
- 적 데이터: `data/enemies/*.lua`
- 보상/전설/상태: `data/rewards/*.lua`, `data/statuses/*.lua`
- 맵 설정: `data/map_configs/*.lua`

## 7. 현재 디렉토리 구조 (요약)

```text
src/
├── anim/      # 카메라 등 연출
├── combat/    # 전투 코어/예측/상태
├── core/      # Game/SceneManager/EventBus/RNG
├── event/     # 이벤트 도메인
├── handler/   # GameScene 내부 서브플로우 핸들러
├── map/       # 맵 그래프/생성
├── reward/    # 보상/각성/전설
├── scene/     # MainMenuScene / GameScene / RunEndScene
├── spell/     # Spell/SpellBook/마나/의심
└── ui/        # 공통 UI + 오버레이

data/          # 게임 밸런스/콘텐츠 데이터
scripts/       # 테스트/러브 실행/검사 스크립트
tests/         # unit/integration 테스트
```

## 문서 메타

- 문서 기준: `origin/main` 구현
- Last Updated: 2026-03-12
