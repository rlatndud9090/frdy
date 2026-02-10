# ralplan 검증: game-core-architecture.md vs 현재 코드베이스

## 검증 일자: 2026-02-10
## 검증 범위: Phase 1~5 (구현 완료 여부), Phase 6~8 (구현 계획 확인)

---

## Phase 1: Core Architecture Setup - COMPLETE

| TODO | 상태 | 비고 |
|------|------|------|
| 1.1 conf.lua | ✅ | 1280x720, t.console=true |
| 1.2 외부 라이브러리 | ✅ | middleclass, flux, lume 배치 |
| 1.3 EventBus | ✅ | subscribe/unsubscribe/emit 구현 |
| 1.4 Scene 추상 클래스 | ✅ | enter/exit/update/draw/keypressed/mousepressed |
| 1.5 SceneManager | ✅ | 스택 기반, draw는 전체 스택 순회 |
| 1.6 Game 싱글턴 | ✅ | SceneManager + EventBus, flux.update 통합 |
| 1.7 main.lua | ✅ | Love2D 콜백 연결 |

**불일치 사항**: 없음

---

## Phase 2: Node-Edge Graph & Map System - COMPLETE

| TODO | 상태 | 비고 |
|------|------|------|
| 2.1 Node 기본 클래스 | ✅ | id, type, position, completed + is_boss() 기본 구현 |
| 2.2 CombatNode, EventNode | ✅ | 각각 enemy_group_id, event_id 보유 |
| 2.3 Edge | ✅ | from_node, to_node, is_available() |
| 2.4 Floor | ✅ | add_node, add_edge, get_nodes, get_edges, get_edges_from, get_start_nodes, get_boss_node |
| 2.5 Map | ✅ | floors, current_floor_index, current_node |
| 2.6 MapGenerator | ✅ | 열 기반 배치, 고아 노드 방지 |
| 2.7 맵 설정 데이터 | ✅ | default_config.lua |

**불일치 사항**:
- CombatNode에 `get_enemy_group()` 메서드 없음 (필드 직접 접근만 가능) → Phase 6에서 추가 필요
- EventNode에 `get_event_id()` 메서드 없음 → Phase 8에서 추가 필요

---

## Phase 3: Screen Management & GameScene - COMPLETE

| TODO | 상태 | 비고 |
|------|------|------|
| 3.1 UIElement 추상 기본 | ✅ | x/y/width/height/visible/hit_test |
| 3.2 Button | ✅ | hover, on_click 콜백 |
| 3.3 Panel | ✅ | 자식 관리, 이벤트 전파 |
| 3.4 Gauge | ✅ | current/max, 색상, 라벨 |
| 3.5 EdgeSelector | ✅ | 엣지 목록에서 버튼 생성, 클릭 콜백 |
| 3.6 GameScene 통합 | ✅ | 9개 페이즈 상태 머신 |
| 3.7 CombatHandler | ⚠️ | 구조만 구현, 실제 전투 로직 없음 (Phase 6에서 구현) |
| 3.8 EventHandler | ⚠️ | 구조만 구현, 실제 이벤트 데이터 없음 (Phase 8에서 구현) |
| 3.9 EdgeSelectHandler | ✅ | EdgeSelector 관리, 단일 엣지 자동 진행 |
| 3.10 MapScene | ✅ | 레거시. 현재 미사용 (GameScene이 대체) |

**불일치 사항**:
- 문서에서 CombatHandler/EventHandler에 on_enter/on_exit 메서드 언급 → 코드에는 activate/deactivate로 구현됨 (동일 기능, 네이밍만 다름 - OK)
- 레거시 Scene 파일 4개(combat_scene, event_scene, edge_select_scene, map_scene) 잔존 → 정리 필요

---

## Phase 4: Animation System & Camera - COMPLETE

| TODO | 상태 | 비고 |
|------|------|------|
| 4.1 Camera 클래스 | ✅ | smooth follow + move_to(flux) + shake + apply/release |
| 4.2 GameScene 페이즈별 애니메이션 | ✅ | flux 기반 fade, slide-in/out |
| 4.3 용사 이동 애니메이션 | ✅ | flux.to(self, duration, {hero_world_x}) |
| 4.5 Game:update에 flux 통합 | ✅ | Game:update에서 flux.update(dt) 호출 |

**불일치 사항**: 없음

---

## Phase 5: Map Visualization - COMPLETE

| TODO | 상태 | 비고 |
|------|------|------|
| 5.1 MapOverlay | ✅ | 전체 맵 오버레이 (GameScene 내부 모듈) |
| 5.2 Minimap | ✅ | 축소 맵 그래프, 깜빡임, 클릭 |
| 5.3 GameScene 통합 | ✅ | M키 토글, 오버레이 입력 차단 |

**추가 구현**: MapUtils 공통 유틸리티 모듈 (PR #1 리뷰 반영)

**불일치 사항**: 없음

---

## Phase 6-8 구현 계획 확인

### Phase 6: Combat System Core - 미구현
필요 파일:
- `src/combat/entity.lua` - Entity 기본 클래스
- `src/combat/hero.lua` - Hero (AI 자동 전투)
- `src/combat/enemy.lua` - Enemy (행동 패턴 기반)
- `src/combat/turn_manager.lua` - 턴 순서 관리 (마왕→용사→적)
- `src/combat/combat_manager.lua` - 전투 전체 흐름
- `src/combat/action_queue.lua` - 행동 대기열
- `data/enemies/floor1_enemies.lua` - 적 데이터
- `src/handler/combat_handler.lua` - 실제 전투 로직 연동으로 리팩토링

**설계 고려사항**:
- 문서에서 "CombatScene 수정"이라 되어있지만, 현재 아키텍처는 GameScene + CombatHandler. CombatHandler를 수정해야 함
- 마왕 턴의 예약 시스템은 Phase 7(카드)과 깊게 연관. Phase 6에서는 기본 턴 흐름(용사→적)만 구현하고, 마왕 턴은 Phase 7에서 통합

### Phase 7: Card, Mana & Suspicion System - 미구현
필요 파일:
- `src/card/card.lua` - Card 기본 클래스
- `src/card/card_effect.lua` - CardEffect Strategy
- `src/card/deck.lua` - Deck 관리
- `src/card/mana_manager.lua` - ManaManager
- `src/card/suspicion_manager.lua` - SuspicionManager
- `src/ui/card_hand.lua` - CardHand UI
- `data/cards/base_cards.lua` - 카드 데이터

### Phase 8: Event System & Integration - 미구현
필요 파일:
- `src/event/event.lua` - Event 클래스
- `src/event/choice.lua` - Choice 클래스
- `src/event/event_manager.lua` - EventManager
- `data/events/floor1_events.lua` - 이벤트 데이터

---

## 정리 필요 사항

1. **레거시 Scene 파일 삭제**: combat_scene.lua, event_scene.lua, edge_select_scene.lua, map_scene.lua
   - GameScene + Handler 패턴으로 대체됨
   - 현재 어디서도 import하지 않음 (Game.init에서 GameScene만 사용)

2. **CombatNode.get_enemy_group() 추가**: Phase 6에서 함께 구현
3. **EventNode.get_event_id() 추가**: Phase 8에서 함께 구현

## 결론

Phase 1~5는 완전히 구현됨. 아키텍처 문서와 코드가 일치함.
Phase 6~8은 미구현 상태이며, 문서의 "CombatScene/EventScene" 참조를 "CombatHandler/EventHandler"로 읽어야 함.
레거시 Scene 파일 4개 정리 필요.
