# Game Core Architecture Plan: 마왕의 은밀한 조력

## 1. Requirements Summary

### Original Request
로그라이크 덱빌딩 게임 "마왕의 은밀한 조력"의 핵심 시스템 아키텍처 설계. Love2D(Lua) 엔진 기반, Slay the Spire 스타일의 노드-엣지 맵 구조를 중심으로 한 전투/이벤트/카드 시스템 구현.

### Core Deliverables
1. **Node-Edge 그래프 맵 시스템** - 절차적 생성, 층(floor) 구조
2. **스크린 매니저** - 전투 화면, 이벤트 화면, 맵 화면 전환
3. **엣지 선택 UI** - 다음 노드 선택 인터페이스
4. **이동 애니메이션** - 벨트스크롤 스타일 우측 이동
5. **맵 시각화** - 전체 맵 오버레이 + 플로팅 미니맵
6. **전투 시스템 기초** - 턴제 전투 프레임워크
7. **이벤트 시스템 기초** - 선택지 기반 이벤트 프레임워크
8. **카드/마력 시스템 기초** - 마왕 개입 카드 프레임워크
9. **의심 시스템 기초** - 핵심 게임 메커니즘

### Definition of Done
- 맵이 절차적으로 생성되고 노드 간 이동이 가능
- 전투 노드 진입 시 턴제 전투가 실행됨
- 이벤트 노드 진입 시 선택지 이벤트가 실행됨
- 엣지 선택 UI가 동작하며 이동 애니메이션이 재생됨
- 전체 맵 보기와 미니맵이 표시됨
- 마왕 카드 사용 시 의심 수치가 변동됨

---

## 2. Architecture Overview

### High-Level Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| OOP 방식 | Middleclass 라이브러리 기반 클래스 시스템 | Lua 네이티브 OOP는 번거로움. middleclass는 경량이며 Love2D 생태계에서 표준 |
| 화면 관리 | State Machine (Scene Stack) | Love2D 콜백을 깔끔하게 위임. push/pop으로 오버레이 지원 |
| 맵 구조 | DAG (Directed Acyclic Graph) | Slay the Spire와 동일한 구조. 층별 전진만 가능 |
| UI 시스템 | 자체 경량 UI 컴포넌트 | 외부 UI 라이브러리 의존 최소화. 게임 특화 위젯만 구현 |
| 애니메이션 | Tween 기반 (flux 라이브러리) | 선언적 애니메이션, 체이닝 지원 |
| 용사 제어 방식 | AI 자동 제어 (플레이어 직접 조작 불가) | 게임의 핵심 정체성. 플레이어는 "마왕"으로서 카드를 통해서만 간접 개입. "은밀한 조력"이라는 컨셉의 근간. 용사는 자체 행동 패턴(AI)에 따라 자동으로 전투를 수행함 |
| 이벤트 버스 | Observer 패턴 (Signal) | 시스템 간 느슨한 결합 |
| 데이터 정의 | Lua 테이블 기반 데이터 파일 | JSON보다 Lua에 자연스럽고 조건부 로직 가능 |

### 외부 라이브러리

| Library | Purpose | Source |
|---------|---------|--------|
| middleclass | OOP class system | `kikito/middleclass` |
| flux | Tween animation | `rxi/flux` |
| lume | Utility functions | `rxi/lume` |

> 모든 라이브러리는 `lib/` 디렉토리에 단일 파일로 포함. LuaRocks 의존 없음.

---

## 3. Class Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        CORE FRAMEWORK                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────┐    ┌──────────────┐    ┌──────────────┐          │
│  │  Game     │───→│ SceneManager │───→│ Scene (base) │          │
│  │ (싱글턴) │    │ (스택 기반)  │    │ (추상 클래스)│          │
│  └──────────┘    └──────────────┘    └──────┬───────┘          │
│       │                                      │                  │
│       │          ┌──────────────┐     ┌──────┴───────────┐     │
│       └─────────→│ EventBus     │     │ Concrete Scenes: │     │
│                  │ (옵저버)     │     │  - GameScene     │     │
│                  └──────────────┘     │    (통합 게임)  │     │
│                       ↑               │  - MapScene      │     │
│                       │               │    (맵/탐색)     │     │
│                  ┌────┴──────┐        └──────────────────┘     │
│                  │  Handlers  │                                 │
│                  │ (모듈들):  │  GameScene 내부 UI 모듈:       │
│                  │ - Combat   │  - Minimap (축소 맵 위젯)     │
│                  │ - Event    │  - MapOverlay (전체 맵 오버레이)│
│                  │ - EdgeSel. │                                 │
│                  └────────────┘  GameScene 내부 페이즈:        │
│                                  - TRAVELING                   │
│                                       - ENTERING/EXITING_COMBAT │
│                                       - COMBAT (handler)        │
│                                       - ENTERING/EXITING_EVENT  │
│                                       - EVENT (handler)         │
│                                       - EDGE_SELECT (handler)   │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                        MAP SYSTEM                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐    ┌──────────┐    ┌──────────────┐          │
│  │ MapGenerator  │───→│ Map      │◆──→│ Floor        │          │
│  │ (팩토리)     │    │ (전체맵) │    │ (층)         │          │
│  └──────────────┘    └──────────┘    └──────┬───────┘          │
│                                              │                  │
│                                       ┌──────┴───────┐         │
│                                       │              │         │
│                                  ┌────┴────┐  ┌─────┴─────┐   │
│                                  │  Node   │◆─│   Edge    │   │
│                                  │ (노드)  │  │  (간선)   │   │
│                                  └────┬────┘  └───────────┘   │
│                                       │                        │
│                                ┌──────┴──────┐                 │
│                                │             │                 │
│                          ┌─────┴─────┐ ┌────┴──────┐          │
│                          │CombatNode │ │EventNode  │          │
│                          └───────────┘ └───────────┘          │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                      COMBAT SYSTEM                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────┐          │
│  │ CombatManager │───→│ TurnManager  │    │ Entity   │          │
│  └──────────────┘    └──────────────┘    │ (base)   │          │
│         │                                 └────┬─────┘          │
│         │            ┌──────────────┐    ┌─────┴─────┐         │
│         └───────────→│ ActionQueue  │    │          │         │
│                      └──────────────┘  ┌─┴──┐  ┌───┴───┐     │
│                                        │Hero│  │Enemy  │     │
│                                        └────┘  └───────┘     │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                    CARD & INTERVENTION SYSTEM                   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────┐    ┌──────────────┐    ┌──────────────┐          │
│  │  Deck    │◆──→│  Card (base) │    │ CardEffect   │          │
│  │ (덱)    │    └──────┬───────┘───→│ (Strategy)   │          │
│  └──────────┘          │             └──────────────┘          │
│                  ┌─────┴──────┐                                │
│                  │            │                                │
│            ┌─────┴────┐┌─────┴─────┐                          │
│            │AidCard   ││HinderCard │                          │
│            │(조력카드)││(방해카드) │                          │
│            └──────────┘└───────────┘                          │
│                                                                │
│  ┌──────────────────┐    ┌──────────────┐                     │
│  │ SuspicionManager │◄───│ ManaManager  │                     │
│  │ (의심 시스템)    │    │ (마력 관리)  │                     │
│  └──────────────────┘    └──────────────┘                     │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                      EVENT SYSTEM                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐      │
│  │EventManager  │───→│ Event (base) │◆──→│ Choice       │      │
│  └──────────────┘    └──────┬───────┘    └──────────────┘      │
│                             │                                   │
│                    (data-driven:                                │
│                     events defined                              │
│                     in data files)                              │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                        UI SYSTEM                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐                                              │
│  │ UIElement    │ (base)                                       │
│  │ (추상)      │                                               │
│  └──────┬───────┘                                              │
│         │                                                      │
│  ┌──────┼──────────┬──────────┬──────────┐                    │
│  │      │          │          │          │                    │
│  │ ┌────┴───┐ ┌────┴───┐ ┌───┴────┐ ┌───┴─────┐            │
│  │ │Button  │ │Panel   │ │Gauge   │ │Minimap  │            │
│  │ └────────┘ └────────┘ └────────┘ └─────────┘            │
│  │                                                           │
│  │ ┌──────────────┐  ┌──────────────┐                       │
│  │ │EdgeSelector  │  │CardHand      │                       │
│  │ │(경로선택UI)  │  │(카드패 UI)   │                       │
│  │ └──────────────┘  └──────────────┘                       │
│  └───────────────────────────────────────────────────────────┘
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                     ANIMATION SYSTEM                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐    ┌──────────────┐                          │
│  │ Camera       │    │ Tween (flux) │                          │
│  │ (카메라/뷰포트)│    │ (보간 엔진)  │                          │
│  └──────────────┘    └──────────────┘                          │
│                                                                 │
│  ┌──────────────┐                                              │
│  │ Transition   │ (화면 전환 효과)                             │
│  └──────────────┘                                              │
└─────────────────────────────────────────────────────────────────┘
```

---

## 4. Class Descriptions

### Core Framework

| Class | Responsibility | Key Methods |
|-------|---------------|-------------|
| **Game** | 전역 싱글턴. Love2D 콜백 진입점. 전역 상태(실행 데이터) 보관 | `init()`, `update(dt)`, `draw()`, `keypressed(key)` |
| **SceneManager** | Scene 스택 관리. push/pop/switch. Love2D 콜백을 활성 Scene으로 위임 | `push(scene)`, `pop()`, `switch(scene)`, `peek()`, `update(dt)`, `draw()` |
| **Scene** | 추상 기본 클래스. 모든 화면의 인터페이스 정의 | `enter(params)`, `exit()`, `update(dt)`, `draw()`, `keypressed(key)`, `mousepressed(x,y,btn)` |
| **EventBus** | 전역 이벤트 발행/구독. 시스템 간 느슨한 결합 | `subscribe(event, callback)`, `unsubscribe(event, callback)`, `emit(event, data)` |

### Map System

| Class | Responsibility | Key Methods |
|-------|---------------|-------------|
| **Map** | 전체 맵 데이터 보관. Floor 목록 관리 | `get_current_floor()`, `get_floor(index)`, `get_total_floors()` |
| **Floor** | 단일 층. Node와 Edge의 그래프 보관. 보스 노드는 별도 BossNode 클래스가 아니라 CombatNode의 특별한 인스턴스 (boss=true 플래그)로 구분. 각 플로어의 마지막 열에 단독 배치됨 | `get_nodes()`, `get_edges_from(node)`, `get_start_nodes()`, `get_boss_node()` |
| **Node** | 맵 위의 한 지점. 타입, 위치, 완료 상태 보관 | `get_type()`, `get_position()`, `is_completed()`, `mark_completed()` |
| **CombatNode** | Node 서브클래스. 전투 데이터(적 구성) 보관. boss=true 플래그로 보스 노드 구분 (별도 BossNode 클래스 없음) | `get_enemy_group()`, `is_boss()` |
| **EventNode** | Node 서브클래스. 이벤트 ID 보관 | `get_event_id()` |
| **Edge** | 두 Node를 연결하는 간선 | `get_from_node()`, `get_to_node()`, `is_available()` |
| **MapGenerator** | 절차적 맵 생성. 층별 노드 배치 및 엣지 생성 | `generate_map(config)`, `generate_floor(floor_index, config)` |

### Combat System

| Class | Responsibility | Key Methods |
|-------|---------------|-------------|
| **CombatManager** | 전투 전체 흐름 관리. 승리/패배 판정 | `start_combat(hero, enemies)`, `end_combat()`, `is_combat_over()` |
| **TurnManager** | 턴 순서 관리 | `next_turn()`, `get_current_entity()`, `get_phase()` |
| **Entity** | 전투 참여자 기본 클래스. HP, 공격력 등 | `take_damage(amount)`, `heal(amount)`, `is_alive()`, `get_stats()` |
| **Hero** | Entity 서브클래스. 용사 고유 로직 | `get_action_pattern()`, `grow(rewards)` |
| **Enemy** | Entity 서브클래스. 적 고유 로직 및 AI | `choose_action()`, `get_intent()` |
| **ActionQueue** | 턴 내 행동 대기열. 카드 효과 포함 | `enqueue(action)`, `process_next()`, `is_empty()` |
| **PredictionEngine** | 마안 예측 엔진. 용사/적 행동 패턴 기반 미래 전투 시뮬레이션 | `generate_timeline(hero, enemies, max_turns)`, `recalculate(interventions)`, `get_timeline()` |
| **PredictedAction** | 예측된 단일 행동 데이터. 주체, 타입, 대상, 수치 보관 | `get_actor()`, `get_type()`, `get_target()`, `get_value()`, `is_intervention()` |
| **TimelineManager** | 타임라인 조작 컨트롤러. 삽입/교환/제거/전역 적용 관리 | `insert_at(index, card)`, `swap(a, b)`, `remove_at(index)`, `apply_global(card)`, `confirm()`, `reset()` |

### Card & Intervention System

| Class | Responsibility | Key Methods |
|-------|---------------|-------------|
| **Card** | 마왕 행동 카드 기본 클래스 | `get_name()`, `get_cost()`, `get_effect()`, `get_suspicion_delta()`, `play(target, context)` |
| **CardEffect** | Strategy 패턴. 카드의 실제 효과 로직 | `apply(target, context)` |
| **Deck** | 덱 관리. 드로우, 셔플, 디스카드 | `draw(count)`, `shuffle()`, `discard(card)`, `add_card(card)`, `remove_card(card)` |
| **ManaManager** | 마력 자원 관리 | `get_current()`, `spend(amount)`, `restore(amount)`, `reset_turn()` |
| **SuspicionManager** | 의심 수치 관리. 게임오버 판정 | `get_level()`, `add(amount)`, `reduce(amount)`, `is_max()`, `get_threshold()` |

### Event System

| Class | Responsibility | Key Methods |
|-------|---------------|-------------|
| **EventManager** | 이벤트 데이터 로딩 및 실행 관리 | `load_events()`, `get_event(id)`, `execute_event(id, context)` |
| **Event** | 단일 이벤트 정의. 텍스트, 선택지 목록 | `get_text()`, `get_choices()`, `get_image()` |
| **Choice** | 이벤트 내 선택지. 효과 및 의심 변동 | `get_text()`, `get_effects()`, `get_suspicion_delta()`, `apply(context)` |

### UI System

| Class | Responsibility | Key Methods |
|-------|---------------|-------------|
| **UIElement** | UI 요소 추상 기본 클래스 | `update(dt)`, `draw()`, `hit_test(x,y)`, `set_position(x,y)`, `set_visible(bool)` |
| **Button** | 클릭 가능한 버튼 | `on_click(callback)`, `set_text(text)` |
| **Panel** | 배경 패널/컨테이너 | `add_child(element)`, `remove_child(element)` |
| **Gauge** | 게이지 바 (HP, 마력, 의심) | `set_value(current, max)`, `set_color(color)` |
| **Minimap** | 플로팅 미니맵 위젯. 축소된 맵 그래프 표시. 클릭 시 MapOverlay 열기 | `set_map_data(floor, node)`, `set_on_click(callback)`, `update(dt)`, `draw()` |
| **EdgeSelector** | 경로 선택 UI. 사용 가능한 엣지 표시 | `show_edges(edges)`, `on_select(callback)`, `hide()` |
| **CardHand** | 카드 패 UI. 펼치기/접기 | `set_cards(cards)`, `on_play(callback)`, `highlight(card)` |
| **TimelineUI** | 마안 타임라인 시각화. 행동 박스 배열, 삽입 슬롯, 드래그 인터랙션 | `set_timeline(actions)`, `set_drag_mode(card)`, `set_manipulate_mode(card)`, `cancel_mode()` |

### Screen Management (Scenes & Handlers)

| Class/Module | Responsibility | Key Methods |
|------|---------------|-------------|
| **GameScene** | 통합 게임플레이 Scene. 페이즈 상태 머신으로 게임 흐름 제어. Map, Hero, Camera 보유. 맵 그래프는 직접 렌더링하지 않고 Minimap/MapOverlay를 통해서만 표시 | `init(map, hero)`, `set_phase(phase)`, `update(dt)`, `draw()`, `keypressed(key)`, `mousepressed(x,y,btn)` |
| **MapScene** | 맵 탐색 화면. 벨트스크롤 뷰. 미니맵, 게이지 표시 | `init(map, hero)`, `update(dt)`, `draw()`, `keypressed(key)` |
| **CombatHandler** | GameScene의 COMBAT 페이즈 전용 모듈. CombatManager와 ActionQueue 관리 | `init()`, `update(dt)`, `draw()`, `on_enter()`, `on_exit()` |
| **EventHandler** | GameScene의 EVENT 페이즈 전용 모듈. EventManager와 선택지 UI 관리 | `init()`, `update(dt)`, `draw()`, `on_enter()`, `on_exit()` |
| **EdgeSelectHandler** | GameScene의 EDGE_SELECT 페이즈 전용 모듈. EdgeSelector UI 관리 | `init()`, `update(dt)`, `draw()`, `on_enter()`, `on_exit()` |
| **MapOverlay** | 전체 맵 시각화 오버레이. GameScene 내부 UI 모듈 (Scene이 아님). 미니맵 클릭 또는 M키로 토글 | `open(floor, node)`, `close()`, `is_open()`, `update(dt)`, `draw()`, `keypressed(key)` |

### Animation System

| Class | Responsibility | Key Methods |
|-------|---------------|-------------|
| **Camera** | 뷰포트 제어. 월드/화면 좌표 변환. flux 기반 부드러운 이동 | `move_to(x, y, duration)`, `shake(intensity, duration)`, `apply()`, `release()`, `get_offset()` |

---

## 5. Design Patterns Used

| Pattern | Where | Why |
|---------|-------|-----|
| **State (Scene Stack)** | SceneManager | 각 화면(전투, 이벤트, 맵)을 독립 State로 관리. push/pop으로 오버레이(맵 오버레이) 지원 |
| **Observer (EventBus)** | EventBus | 시스템 간 직접 참조 제거. "combat_end" 이벤트 발생 시 맵, 의심, 성장 시스템이 독립적으로 반응 |
| **Factory** | MapGenerator | 맵 생성 알고리즘 캡슐화. config에 따라 다양한 맵 형태 생성 가능 |
| **Strategy** | CardEffect | 카드 효과를 독립 객체로 분리. 새 카드 추가 시 Card 클래스 수정 불필요 |
| **Template Method** | Scene, Entity, Node | 기본 클래스에서 흐름 정의, 서브클래스에서 구체적 동작 구현 |
| **Singleton** | Game | 전역 접근 필요한 최소 객체만 싱글턴. Game 하나로 한정 |
| **Composite** | Panel > UIElement | UI 요소의 트리 구조. Panel이 자식 요소 관리 |
| **Command** | ActionQueue | 전투 행동을 객체화. 큐잉, 취소, 재실행 지원 |

---

## 6. File Structure

```
frdy/
├── main.lua                     -- Love2D 진입점. Game:init() 호출
├── conf.lua                     -- Love2D 설정 (해상도, 타이틀 등)
│
├── lib/                         -- 외부 라이브러리 (수정 금지)
│   ├── middleclass.lua          -- OOP 클래스 시스템
│   ├── flux.lua                 -- Tween 애니메이션
│   └── lume.lua                 -- 유틸리티 함수
│
├── src/                         -- 게임 소스코드
│   ├── core/                    -- 핵심 프레임워크
│   │   ├── game.lua             -- Game 싱글턴
│   │   ├── scene_manager.lua    -- Scene 스택 관리
│   │   ├── scene.lua            -- Scene 추상 기본 클래스
│   │   └── event_bus.lua        -- 전역 이벤트 발행/구독
│   │
│   ├── map/                     -- 맵 시스템
│   │   ├── map.lua              -- Map 전체 맵
│   │   ├── floor.lua            -- Floor 층
│   │   ├── node.lua             -- Node 기본 클래스
│   │   ├── combat_node.lua      -- CombatNode
│   │   ├── event_node.lua       -- EventNode
│   │   ├── edge.lua             -- Edge 간선
│   │   └── map_generator.lua    -- MapGenerator 절차적 생성
│   │
│   ├── combat/                  -- 전투 시스템
│   │   ├── combat_manager.lua   -- 전투 전체 관리
│   │   ├── turn_manager.lua     -- 턴 순서 관리
│   │   ├── entity.lua           -- Entity 기본 클래스
│   │   ├── hero.lua             -- Hero 용사
│   │   ├── enemy.lua            -- Enemy 적
│   │   ├── action_queue.lua     -- ActionQueue 행동 대기열
│   │   ├── prediction_engine.lua -- 마안 예측 엔진
│   │   ├── predicted_action.lua  -- 예측된 행동 데이터
│   │   └── timeline_manager.lua  -- 타임라인 조작 관리
│   │
│   ├── card/                    -- 카드/개입 시스템
│   │   ├── card.lua             -- Card 기본 클래스
│   │   ├── card_effect.lua      -- CardEffect 전략 패턴
│   │   ├── deck.lua             -- Deck 덱 관리
│   │   ├── mana_manager.lua     -- ManaManager 마력
│   │   └── suspicion_manager.lua -- SuspicionManager 의심
│   │
│   ├── event/                   -- 이벤트 시스템
│   │   ├── event_manager.lua    -- EventManager
│   │   ├── event.lua            -- Event 기본 클래스
│   │   └── choice.lua           -- Choice 선택지
│   │
│   ├── scene/                   -- Scene 구현
│   │   ├── game_scene.lua       -- GameScene (통합 게임플레이 - 페이즈 상태머신)
│   │   └── map_scene.lua        -- MapScene (맵/탐색 화면)
│   │
│   ├── handler/                 -- GameScene 페이즈 핸들러들
│   │   ├── combat_handler.lua   -- 전투 페이즈 로직
│   │   ├── event_handler.lua    -- 이벤트 페이즈 로직
│   │   └── edge_select_handler.lua -- 경로 선택 페이즈 로직
│   │
│   ├── ui/                      -- UI 시스템
│   │   ├── ui_element.lua       -- UIElement 추상 기본
│   │   ├── button.lua           -- Button
│   │   ├── panel.lua            -- Panel 컨테이너
│   │   ├── gauge.lua            -- Gauge 게이지 바
│   │   ├── minimap.lua          -- Minimap 미니맵 (축소 맵 그래프 위젯)
│   │   ├── map_overlay.lua      -- MapOverlay (전체 맵 오버레이 UI 모듈)
│   │   ├── edge_selector.lua    -- EdgeSelector 경로 선택 UI
│   │   ├── card_hand.lua        -- CardHand 카드 패 UI
│   │   └── timeline_ui.lua     -- TimelineUI 마안 타임라인 위젯
│   │
│   └── anim/                    -- 애니메이션 시스템
│       └── camera.lua           -- Camera (뷰포트, flux 기반 이동)
│
├── data/                        -- 게임 데이터 정의 (Lua 테이블)
│   ├── enemies/                 -- 적 정의
│   │   └── floor1_enemies.lua
│   ├── events/                  -- 이벤트 정의
│   │   └── floor1_events.lua
│   ├── cards/                   -- 카드 정의
│   │   └── base_cards.lua
│   └── map_configs/             -- 맵 생성 설정
│       └── default_config.lua
│
├── assets/                      -- 에셋 (아트, 사운드)
│   ├── sprites/                 -- 스프라이트
│   │   ├── hero/
│   │   ├── enemies/
│   │   ├── ui/
│   │   └── map/
│   ├── fonts/
│   └── sounds/
│       ├── bgm/
│       └── sfx/
│
├── GAME_CONCEPT.md
├── AGENTS.md
├── COMMIT_CONVENTION.md
└── README.md
```

---

## 7. Implementation Phases

### Must Have (Guardrails)
- OOP 설계 원칙 (SOLID) 준수
- middleclass 라이브러리를 통한 클래스 시스템
- Snake_case 함수/변수, PascalCase 클래스 (AGENTS.md 규칙)
- 들여쓰기 2 spaces
- 모든 커밋은 Conventional Commits 규칙 준수
- 각 Phase 완료 시 독립적으로 실행 가능해야 함

### Must NOT Have (이번 범위 제외)
- 실제 그래픽 에셋 (placeholder 사용)
- 사운드/음악
- 밸런싱 데이터 (테스트용 더미 데이터만)
- 세이브/로드 시스템
- 메뉴/타이틀 화면
- 다국어 지원

---

### Phase 1: Core Architecture Setup

**목표**: 프로젝트 기반 구조 구축. Love2D 콜백과 Scene 시스템 연결.

**파일 목록**:
- `conf.lua`
- `lib/middleclass.lua`
- `lib/flux.lua`
- `lib/lume.lua`
- `src/core/game.lua`
- `src/core/scene_manager.lua`
- `src/core/scene.lua`
- `src/core/event_bus.lua`
- `main.lua` (수정)

**TODO 1.1**: `conf.lua` 생성
- Love2D 윈도우 설정: 1280x720, 타이틀 "마왕의 은밀한 조력"
- `t.console = true` (개발 중 디버그)
- **수락 기준**: `love.conf` 함수가 정상 호출됨

**TODO 1.2**: 외부 라이브러리 배치
- `lib/` 디렉토리에 middleclass, flux, lume 배치
- **수락 기준**: `require('lib.middleclass')` 정상 로딩

**TODO 1.3**: EventBus 구현
- subscribe(event_name, callback), unsubscribe, emit 메서드
- 다수 구독자 지원
- **수락 기준**: emit 시 모든 구독자 콜백 호출됨

**TODO 1.4**: Scene 추상 클래스 구현
- enter(params), exit(), update(dt), draw(), keypressed(key), mousepressed(x,y,btn) 인터페이스
- 기본 구현은 빈 함수 (서브클래스에서 오버라이드)
- **수락 기준**: Scene:new() 생성 가능, 모든 메서드 호출 가능

**TODO 1.5**: SceneManager 구현
- 스택 기반 Scene 관리: push(scene, params), pop(), switch(scene, params)
- peek()로 현재 활성 Scene 반환
- update(dt), draw()를 스택 최상위 Scene에 위임
- draw 시: 스택 전체 draw (하위 Scene도 보임, 오버레이 지원)
- **수락 기준**: push/pop/switch 동작. update/draw가 활성 Scene으로 위임됨

**TODO 1.6**: Game 싱글턴 구현
- SceneManager, EventBus 인스턴스 보관
- love.load → Game:init(), love.update → Game:update(dt), love.draw → Game:draw()
- love.keypressed, love.mousepressed 위임
- **수락 기준**: Love2D 실행 시 Game이 초기화되고 빈 화면 표시

**TODO 1.7**: main.lua 수정
- Game 싱글턴 생성 및 Love2D 콜백 연결
- **수락 기준**: `love .` 실행 시 1280x720 윈도우 표시, 에러 없음

**커밋**: `feat(core): 핵심 프레임워크 구현 (Game, SceneManager, EventBus)`

---

### Phase 2: Node-Edge Graph & Map System

**목표**: 맵 데이터 구조와 절차적 맵 생성.

**파일 목록**:
- `src/map/node.lua`
- `src/map/combat_node.lua`
- `src/map/event_node.lua`
- `src/map/edge.lua`
- `src/map/floor.lua`
- `src/map/map.lua`
- `src/map/map_generator.lua`
- `data/map_configs/default_config.lua`

**TODO 2.1**: Node 기본 클래스 구현
- 속성: id, type, position(x,y), completed(bool), floor_index
- 메서드: get_type(), get_position(), is_completed(), mark_completed()
- **수락 기준**: Node 인스턴스 생성 및 속성 접근 가능

**TODO 2.2**: CombatNode, EventNode 서브클래스 구현
- CombatNode: enemy_group_id 속성 추가
- EventNode: event_id 속성 추가
- **수락 기준**: 각 서브클래스가 고유 데이터를 보관하고 get_type()이 올바른 값 반환

**TODO 2.3**: Edge 클래스 구현
- 속성: from_node, to_node
- 메서드: get_from_node(), get_to_node(), is_available()
- **수락 기준**: Edge가 두 Node를 연결하고 접근 가능

**TODO 2.4**: Floor 클래스 구현
- Node 목록과 Edge 목록 관리
- 메서드: add_node(node), add_edge(edge), get_nodes(), get_edges_from(node), get_start_nodes()
- **수락 기준**: 노드와 엣지를 추가/조회 가능. get_edges_from이 특정 노드의 나가는 엣지만 반환

**TODO 2.5**: Map 클래스 구현
- Floor 목록 관리
- current_floor_index, current_node 추적
- 메서드: get_current_floor(), advance_floor(), get_current_node(), set_current_node(node)
- **수락 기준**: Floor 탐색 및 현재 위치 추적 가능

**TODO 2.6**: MapGenerator 구현
- default_config 기반 맵 생성:
  - 층 수: 3 (설정 가능)
  - **열(column) 기반 배치 알고리즘**:
    - 노드는 열(column)로 배치됨 (단계당 하나의 열)
    - 열 0 = 시작 노드 (1개)
    - 열 1 ~ N-1 = 중간 노드, 각 열에 random_range(min_nodes, max_nodes) 개의 노드 배치 (기본: 2~4개)
    - 열 N = 보스 노드 (1개, 단독 배치)
    - 엣지는 오직 열 i에서 열 i+1로만 연결 (DAG 보장)
  - 층당 열 수: 5~8 (시작/보스 포함, 랜덤)
  - 노드 타입 비율: 전투 70%, 이벤트 30%
  - 엣지 연결: 각 노드에서 다음 열로 1~3개 연결
  - 시작 노드, 보스 노드 보장
  - 모든 노드가 최소 1개의 들어오는 엣지를 가져야 함 (고아 노드 방지)
- DAG 구조 보장 (사이클 없음, 열 간 전진만 가능)
- **수락 기준**: generate_map() 호출 시 유효한 Map 인스턴스 반환. 모든 노드가 연결되어 있고 시작점에서 보스까지 경로 존재. 엣지가 열 i→i+1 방향으로만 존재

**TODO 2.7**: 맵 생성 설정 데이터 파일
- `data/map_configs/default_config.lua` 작성
- 층 수, 노드 수 범위, 타입 비율, 엣지 수 범위 정의
- **수락 기준**: 설정 파일 로딩 후 MapGenerator에 전달 가능

**커밋**: `feat(map): Node-Edge 그래프 맵 시스템 및 절차적 생성 구현`

---

### Phase 3: Screen Management & Unified GameScene Architecture

**목표**: UI 기본 위젯 구현. 통합 GameScene 구현 - 페이즈 상태 머신으로 모든 게임플레이를 관리. 경로 선택 UI와 헨들러들 구현.

**아키텍처 변경**:
- **Before**: MapScene, CombatScene, EventScene, EdgeSelectScene 4개의 독립 Scene
- **After**: GameScene 1개 + CombatHandler, EventHandler, EdgeSelectHandler 3개의 헨들러 모듈
  - GameScene은 phase 상태 머신으로 게임플레이 흐름 제어
  - Handlers는 Scene이 아닌 헬퍼 모듈로, 특정 페이즈의 로직을 캡슐화

**GameScene 페이즈 상태 머신**:
- `TRAVELING` - 맵 화면. 용사 이동 애니메이션 중
- `ARRIVING` - 도착 노드에서 일시 정지. 노드 콘텐츠 준비
- `ENTERING_COMBAT` - 전투 페이즈로 전환 중 (Transition)
- `COMBAT` - 턴제 전투 진행 (CombatHandler 관리)
- `EXITING_COMBAT` - 전투 종료 (Transition)
- `ENTERING_EVENT` - 이벤트 페이즈로 전환 중 (Transition)
- `EVENT` - 이벤트 선택지 표시 (EventHandler 관리)
- `EXITING_EVENT` - 이벤트 종료 (Transition)
- `EDGE_SELECT` - 경로 선택 UI 표시 (EdgeSelectHandler 관리)

**파일 목록**:
- `src/ui/ui_element.lua`
- `src/ui/button.lua`
- `src/ui/panel.lua`
- `src/ui/gauge.lua`
- `src/scene/game_scene.lua` - 통합 GameScene (NEW)
- `src/handler/combat_handler.lua` - 전투 페이즈 관리 (NEW)
- `src/handler/event_handler.lua` - 이벤트 페이즈 관리 (NEW)
- `src/handler/edge_select_handler.lua` - 경로 선택 관리 (NEW)
- `src/ui/edge_selector.lua`

**TODO 3.1**: UIElement 추상 기본 클래스 구현
- 속성: x, y, width, height, visible, parent
- 메서드: update(dt), draw(), hit_test(x,y), set_position(x,y), set_visible(bool)
- **수락 기준**: 서브클래스가 상속하여 사용 가능

**TODO 3.2**: Button 위젯 구현
- 텍스트 라벨, 배경색, hover 상태
- on_click(callback) 콜백 등록
- mousepressed 시 hit_test → callback 실행
- **수락 기준**: 버튼 클릭 시 등록된 콜백 실행. hover 시 시각적 변화

**TODO 3.3**: Panel 컨테이너 구현
- 자식 UIElement 목록 관리
- add_child, remove_child
- update/draw 시 자식 순회
- **수락 기준**: Panel에 Button 추가 후 함께 그려짐

**TODO 3.4**: Gauge 위젯 구현
- 현재값/최대값 표시 (HP, 마력, 의심용)
- 색상 커스터마이징
- **수락 기준**: set_value(50, 100) → 50% 채워진 게이지 표시

**TODO 3.5**: EdgeSelector UI 위젯 구현
- 사용 가능한 경로를 시각적으로 표시 (노드 타입 아이콘 포함)
- 마우스 hover, 클릭 상호작용
- **수락 기준**: 복수 엣지 표시, 클릭 시 선택 콜백 실행

**TODO 3.6**: GameScene 통합 구현
- Scene 기본 클래스 상속
- 페이즈 상태 머신: phase 속성, phase_transitions 로직
- 맵 데이터 보유: current_node, map, hero
- 현재 페이즈에 따라 update(dt), draw() 위임
- 페이즈 전환 트리거:
  - TRAVELING → ARRIVING (도착 지점에서)
  - ARRIVING → EDGE_SELECT (매 턴) 또는 ENTERING_COMBAT/ENTERING_EVENT (노드 타입에 따라)
  - ENTERING_COMBAT → COMBAT (Transition 완료 시)
  - COMBAT → EXITING_COMBAT (전투 종료 시)
  - EXITING_COMBAT → ARRIVING 또는 EDGE_SELECT (Transition 완료 시)
  - 이벤트도 동일 흐름
- **수락 기준**: 게임 시작 시 GameScene 진입. 페이즈 전환이 정상 동작

**TODO 3.7**: CombatHandler 구현
- 전투 페이즈 전용 로직 캡슐화
- 메서드: init(), update(dt), draw(), on_enter(), on_exit()
- CombatManager, TurnManager, ActionQueue는 여기서 관리
- GameScene의 COMBAT 페이즈에서만 활성화
- **수락 기준**: CombatHandler가 GameScene과 협력하여 전투 진행

**TODO 3.8**: EventHandler 구현
- 이벤트 페이즈 전용 로직 캡슐화
- 메서드: init(), update(dt), draw(), on_enter(), on_exit()
- EventManager, 선택지 UI 관리
- GameScene의 EVENT 페이즈에서만 활성화
- **수락 기준**: EventHandler가 GameScene과 협력하여 이벤트 진행

**TODO 3.9**: EdgeSelectHandler 구현
- 경로 선택 페이즈 전용 로직
- 메서드: init(), update(dt), draw(), on_enter(), on_exit()
- EdgeSelector UI 관리
- 선택 완료 시 GameScene에 다음 노드 전달
- **수락 기준**: 경로 선택 UI가 표시되고 선택 시 콜백 실행

**TODO 3.10**: MapScene 구현 (GameScene과 별도)
- 벨트스크롤 뷰: 용사가 우측으로 이동
- **벨트스크롤 좌표계**:
  - 각 플로어의 단계(열, column)가 하나의 수평 세그먼트에 매핑됨 (SEGMENT_WIDTH = 300px)
  - hero의 월드 좌표 world_x = current_column * SEGMENT_WIDTH
  - 노드의 월드 좌표도 동일하게 column 기반으로 배치
  - Camera가 hero.world_x를 추적하여 뷰포트 오프셋 결정
  - 화면 좌표 = 월드 좌표 - camera.offset_x
- 현재 노드 시각적 표시 (placeholder 도형)
- 미니맵, 의심 게이지, 마력 게이지 배치
- **수락 기준**: MapScene 진입 시 용사와 맵이 표시됨. 노드 이동 애니메이션 재생

**커밋 1**: `feat(ui): 기본 UI 위젯 시스템 구현 (UIElement, Button, Panel, Gauge, EdgeSelector)`
**커밋 2**: `feat(scene): 통합 GameScene 페이즈 상태 머신 구현`
**커밋 3**: `feat(handler): 전투/이벤트/경로선택 핸들러 모듈 구현`
**커밋 4**: `feat(scene): MapScene 벨트스크롤 뷰 구현`

---

### Phase 4: Animation System & Camera

**목표**: 카메라 시스템 구현, flux 기반 애니메이션 통합, 벨트스크롤 애니메이션 완성.

**설계 개선**:
- **Before**: 별도 Transition 클래스 + 화면 전환 효과 관리
- **After**: flux tween 라이브러리로 모든 애니메이션 처리
  - Camera는 flux tween으로 위치 이동 (apply/release 메서드로 love.graphics.translate 제어)
  - UI 페이드/슬라이드도 flux로 처리
  - Game:update(dt)에서 flux.update(dt) 호출하여 모든 tween 업데이트
  - Transition 관련 로직은 GameScene의 페이즈 전환에서 flux tween으로 구현

**파일 목록**:
- `src/anim/camera.lua`
- `src/scene/game_scene.lua` (수정)
- `src/scene/map_scene.lua` (수정)

**TODO 4.1**: Camera 클래스 구현
- 뷰포트 offset (x, y) 관리
- move_to(target_x, target_y, duration): flux tween으로 부드러운 이동
  - 내부적으로 `flux.to(self, duration, {offset_x = target_x, offset_y = target_y})`
  - 콜백 옵션으로 tween 완료 후 로직 연결
- shake(intensity, duration): 화면 흔들림 효과
  - 여러 번의 작은 tween으로 흔들림 구현
- apply(): 현재 offset을 love.graphics.translate에 적용
- release(): transform 상태 복원
- get_offset(): 현재 오프셋 반환
- **수락 기준**: Camera:move_to 호출 시 화면이 부드럽게 스크롤됨. apply/release로 변환 관리

**TODO 4.2**: GameScene 페이즈별 애니메이션 통합
- TRAVELING → ARRIVING: 즉시 전환 또는 0.2초 페이드
- ARRIVING → EDGE_SELECT: 0.3초 페이드 인
- ENTERING_COMBAT: 0.5초 fade to black + 배경 전환
- EXITING_COMBAT: 0.5초 fade from black
- 이벤트도 동일 패턴 (0.5초 fade)
- 모든 fade는 flux 기반 UI 레이어(semi-transparent 오버레이) 알파 tween으로 구현
- **수락 기준**: 페이즈 전환 시 자동으로 fade 효과 재생

**TODO 4.3**: MapScene 용사 이동 애니메이션
- 엣지 선택 후 TRAVELING 페이즈 시작
- hero.world_x를 현재 위치 → 도착 노드 위치로 flux tween
- Camera는 hero를 추적하여 자동으로 move_to (또는 직접 계산)
- 이동 duration: 노드 거리에 비례 (기본: 2초)
- 이동 완료 시 ARRIVING으로 전환
- **수락 기준**: 경로 선택 → 용사가 부드럽게 우측 이동 → 카메라 따라 스크롤

**TODO 4.4**: UI 슬라이드 애니메이션 (선택사항)
- CardHand, EdgeSelector 등이 화면에 나타날 때 슬라이드 인
- flux 기반 위치 tween으로 구현
- **수락 기준**: UI 등장 시 자연스러운 슬라이드 애니메이션

**TODO 4.5**: Game:update(dt)에 flux 통합
- `flux.update(dt)` 호출하여 모든 tween 업데이트
- Camera 위치 변동 → draw 시 apply() 호출
- **수락 기준**: Game 시작 후 모든 tween 애니메이션이 정상 재생

**커밋 1**: `feat(anim): Camera 클래스 및 flux 기반 애니메이션 통합`
**커밋 2**: `feat(scene): GameScene 페이즈별 페이드 효과 구현`
**커밋 3**: `feat(scene): 용사 이동 애니메이션 및 카메라 추적 완성`

---

### Phase 5: Map Visualization

**목표**: 전체 맵 오버레이와 플로팅 미니맵.

**파일 목록**:
- `src/scene/map_overlay.lua`
- `src/ui/minimap.lua`
- `src/scene/map_scene.lua` (수정)

**TODO 5.1**: MapOverlay UI 모듈 구현 ✅ (구현 완료)
- GameScene 내부 UI 모듈로 구현 (별도 Scene이 아님)
- 화면 전체를 덮는 반투명 어둠 배경 + 전체 맵 그래프 시각화
- 노드 타입별 색상, 완료 상태, 현재 위치 강조, 엣지 표시
- ESC/M키 또는 닫기 버튼으로 닫기
- flux tween으로 fade in/out 애니메이션
- **변경 이유**: SceneManager push 시 GameScene의 tween이 멈추는 문제 회피. Handler 패턴과 일관성 유지
- **수락 기준**: 미니맵 클릭 또는 M키로 오버레이 토글. 전체 노드/엣지/현재위치 시각화

**TODO 5.2**: Minimap 위젯 구현 ✅ (구현 완료)
- GameScene 우측 상단에 고정 배치 (200x100)
- 축소된 맵 그래프 표시 (월드 좌표→미니맵 좌표 스케일 변환)
- 현재 위치 깜빡임 표시
- 클릭 시 MapOverlay 열기
- **수락 기준**: GameScene에서 항상 미니맵 표시. 현재 위치 표시. 클릭 시 전체 맵 열기

**TODO 5.3**: GameScene에 미니맵 및 맵 오버레이 통합 ✅ (구현 완료)
- GameScene에서 Node-Edge 그래프 직접 렌더링 제거 (_draw_world에서 노드/엣지 삭제)
- Minimap 위젯 배치 (기존 minimap_button 대체)
- MapOverlay 인스턴스 생성 및 토글 로직
- 전체 맵 보기 단축키 (M키) 추가
- 오버레이 열림 시 입력 이벤트 차단 (오버레이에만 전달)
- **수락 기준**: M키 또는 미니맵 클릭으로 MapOverlay 토글. GameScene 배경에 노드/엣지 없음

**커밋**: `feat(map): 전체 맵 오버레이 및 플로팅 미니맵 구현`

---

### Phase 6: Combat System Core

**목표**: 실제 턴제 전투 로직 구현. CombatScene과 연결.

**파일 목록**:
- `src/combat/entity.lua`
- `src/combat/hero.lua`
- `src/combat/enemy.lua`
- `src/combat/turn_manager.lua`
- `src/combat/combat_manager.lua`
- `src/combat/action_queue.lua`
- `src/scene/combat_scene.lua` (수정)
- `data/enemies/floor1_enemies.lua`

**TODO 6.1**: Entity 기본 클래스 구현
- 속성: name, hp, max_hp, attack, defense
- 메서드: take_damage(amount), heal(amount), is_alive(), get_stats()
- **수락 기준**: Entity 인스턴스 생성, 데미지 적용 시 HP 감소, 0 이하 시 is_alive() == false

**TODO 6.2**: Hero 클래스 구현
- Entity 상속
- 추가 속성: level, experience
- grow(rewards): 전투 승리 시 능력치 성장
- 행동 패턴: 기본 공격 (자동 실행, AI 제어)
- **수락 기준**: Hero 생성 및 성장 적용 가능

**TODO 6.3**: Enemy 클래스 구현
- Entity 상속
- 행동 패턴 데이터 기반 정의
- choose_action(): 패턴에 따라 다음 행동 결정
- get_intent(): 현재 의도(행동 예고) 표시용
- **수락 기준**: Enemy가 데이터 기반으로 생성되고 행동 선택 가능

**TODO 6.4**: TurnManager 구현
- 턴 순서: (마왕 개입) → 용사 → 적 → 반복
- 페이즈: DEMON_LORD_TURN, HERO_TURN, ENEMY_TURN
- **예약 시스템 (Reservation System)**:
  - 마왕의 카드는 즉시 실행되지 않고 '예약'됨
  - 카드 효과는 특정 트리거 시점에 발동 (예: "공격받을 때", "공격할 때", "턴 시작 시")
  - 예시: '방어막 부여' 카드 → 효과: "공격받을 때 방어도 5 부여" → 용사에게 사용 → 용사가 적의 공격을 받을 때 효과 발동
- **의도 표시 (Intent Display)**:
  - 마왕 턴에 용사와 적의 다음 행동을 미리 표시 (슬레이 더 스파이어 스타일)
  - Hero와 Enemy는 각각 get_intent()를 통해 다음 행동(공격/방어/스킬)과 대상 표시
  - UI에 "용사 → 적1 공격 (데미지 5)", "적1 → 용사 공격 (데미지 8)" 형태로 표시
- next_turn(): 다음 턴으로 진행
- **수락 기준**: 턴 순서가 (마왕 → 용사 → 적)으로 올바르게 순환. 마왕 턴에 용사/적의 의도 표시. 예약된 카드 효과가 트리거 시점에 발동

**TODO 6.5**: ActionQueue 구현
- 행동(Action) 객체 큐잉
- process_next(): 다음 행동 실행
- 카드 효과도 Action으로 삽입
- **수락 기준**: 여러 행동을 큐에 넣고 순서대로 실행

**TODO 6.6**: CombatManager 구현
- start_combat(hero, enemy_group): 전투 시작
- TurnManager, ActionQueue 조율
- 승리 조건: 모든 적 HP 0
- 패배 조건: 용사 HP 0
- 전투 종료 시 EventBus로 "combat_end" 이벤트 발행
- **수락 기준**: 전투가 턴 단위로 진행. 승리/패배 판정 동작

**TODO 6.7**: CombatScene 실제 전투 연결
- CombatManager와 연결
- 턴 진행 시각화 (용사 공격, 적 공격 표시)
- 마왕 개입 턴에 카드 사용 UI (Phase 7과 연결, 여기선 "패스" 버튼)
- 전투 종료 시 결과 표시 → MapScene 복귀
- **수락 기준**: 전투 노드에서 실제 턴제 전투가 진행되고 결과에 따라 진행

**TODO 6.8**: 적 데이터 파일 작성
- `data/enemies/floor1_enemies.lua`: 3~5종 기본 적 정의
- 이름, HP, 공격력, 행동 패턴
- **수락 기준**: 데이터 파일에서 적 정보 로딩 가능

**커밋 1**: `feat(combat): Entity/Hero/Enemy 전투 엔티티 구현`
**커밋 2**: `feat(combat): 턴제 전투 시스템 구현 (TurnManager, CombatManager)`

---

### Phase 7: Card, Mana & Suspicion System

**목표**: 마왕의 개입 시스템 핵심. 카드, 마력, 의심 수치.

**파일 목록**:
- `src/card/card.lua`
- `src/card/card_effect.lua`
- `src/card/deck.lua`
- `src/card/mana_manager.lua`
- `src/card/suspicion_manager.lua`
- `src/ui/card_hand.lua`
- `src/scene/combat_scene.lua` (수정)
- `data/cards/base_cards.lua`

**TODO 7.1**: Card 기본 클래스 구현
- 속성: id, name, description, cost (마력), suspicion_delta, effect
- play(target, context): 마력 소모 → 효과 적용 → 의심 변동
- **수락 기준**: Card 인스턴스 생성 및 play 호출 가능

**TODO 7.2**: CardEffect Strategy 구현
- 효과 타입별 클래스:
  - HealEffect: 용사 체력 회복
  - DamageEffect: 적에게 추가 데미지
  - BuffEffect: 용사 임시 버프
  - DebuffEffect: 적 임시 디버프
  - HinderEffect: 용사 약화 (의심 감소용)
- **수락 기준**: 각 효과가 올바르게 적용됨

**TODO 7.3**: Deck 구현
- draw_pile, hand, discard_pile 관리
- draw(count), shuffle(), discard(card), add_card(card)
- 턴 시작 시 자동 드로우
- **수락 기준**: 덱에서 카드 드로우, 사용 후 디스카드, 셔플 동작

**TODO 7.4**: ManaManager 구현 (코스트 기반)
- **하스스톤/슬레이 더 스파이어 스타일 마나 시스템**:
  - 매 턴마다 마나 제공 (턴 시작 시 자동 충전)
  - 카드마다 고유한 마나 코스트 존재
  - 현재 마나(current_mana), 턴 마나(turn_mana) 관리
- spend(cost): 카드 사용 시 마나 차감 (부족 시 사용 불가)
- can_afford(cost): 카드 사용 가능 여부 체크
- start_turn(mana_amount): 턴 시작 시 마나 충전 (예: 턴 1 = 1마나, 턴 2 = 2마나, 최대 10마나)
- **수락 기준**: 턴마다 마나 충전. 카드 사용 시 코스트만큼 차감. 부족 시 카드 사용 불가

**TODO 7.5**: SuspicionManager 구현
- 현재 의심 수치, 최대 수치 (100)
- add(amount), reduce(amount)
- is_max(): 게임오버 판정
- EventBus로 "suspicion_change", "suspicion_max" 이벤트 발행
- **수락 기준**: 의심 수치 증감 동작. MAX 도달 시 이벤트 발행

**TODO 7.6**: CardHand UI 구현
- 화면 하단에 카드 패 표시
- 카드 hover 시 확대/설명
- 카드 클릭/드래그로 사용
- 마력 부족 시 비활성 표시
- **수락 기준**: 카드 패가 화면에 표시되고 클릭으로 사용 가능

**TODO 7.7**: CombatScene에 카드 시스템 통합
- DEMON_LORD_TURN 페이즈에서 카드 사용 UI 활성화
- 카드 사용 또는 패스 후 다음 턴 진행
- 의심 게이지 실시간 반영
- **수락 기준**: 전투 중 마왕 턴에 카드를 사용하고 의심 수치가 변동됨

**TODO 7.8**: 카드 데이터 파일 작성
- `data/cards/base_cards.lua`: 6~8장 기본 카드 정의
- 조력 카드 3~4장, 방해 카드 3~4장
- **수락 기준**: 데이터 파일에서 카드 정보 로딩 가능

**커밋 1**: `feat(card): 카드/덱/마력 시스템 구현`
**커밋 2**: `feat(suspicion): 의심 수치 시스템 구현`
**커밋 3**: `feat(card): CombatScene에 카드 사용 UI 통합`

---

### Phase 8: Event System & Integration

**목표**: 이벤트 시스템 구현. 전체 게임 루프 완성.

**파일 목록**:
- `src/event/event.lua`
- `src/event/choice.lua`
- `src/event/event_manager.lua`
- `src/scene/event_scene.lua` (수정)
- `data/events/floor1_events.lua`

**TODO 8.1**: Event, Choice 클래스 구현
- Event: id, title, description, image_id, choices 목록
- Choice: text, effects (리스트), suspicion_delta
- Choice:apply(context): 효과 적용 (용사 강화/약화, 의심 변동 등)
- **수락 기준**: Event와 Choice 인스턴스 생성 가능

**TODO 8.2**: EventManager 구현
- 데이터 파일에서 이벤트 로딩
- get_event(id): ID로 이벤트 조회
- 랜덤 이벤트 선택 로직
- **수락 기준**: 이벤트 데이터 로딩 및 조회 가능

**TODO 8.3**: EventScene 실제 이벤트 연결
- EventManager에서 이벤트 로딩
- 이벤트 텍스트 표시
- 마왕의 선택지 표시 (각 선택지의 효과/의심 변동 미리보기)
- 선택 시 효과 적용 → MapScene 복귀
- **수락 기준**: 이벤트 노드에서 텍스트와 선택지 표시. 선택 시 효과 적용

**TODO 8.4**: 이벤트 데이터 파일 작성
- `data/events/floor1_events.lua`: 4~6개 기본 이벤트 정의
- 조력/방해 선택지 포함
- **수락 기준**: 데이터 파일에서 이벤트 정보 로딩 가능

**TODO 8.5**: 전체 게임 루프 통합 테스트
- 맵 생성 → 노드 이동 → 전투/이벤트 → 엣지 선택 → 반복
- 의심 MAX 시 게임오버 처리
- 마지막 노드 클리어 시 층 진행
- **수락 기준**: 1층 전체를 플레이 가능. 전투/이벤트/이동/카드/의심 시스템이 연동됨

**커밋 1**: `feat(event): 이벤트/선택지 시스템 구현`
**커밋 2**: `feat(core): 전체 게임 루프 통합 및 게임오버 처리`

---

### Phase 9: 진로 수정 (마왕의 경로 개입)

**목표**: 마왕이 용사의 이동 경로를 은밀히 조작하는 기능. GAME_CONCEPT.md의 "진로 수정" 메커니즘 구현.

**파일 목록**:
- `src/scene/edge_select_scene.lua` (수정)
- `src/card/suspicion_manager.lua` (수정)
- `src/ui/edge_selector.lua` (수정)

**TODO 9.1**: EdgeSelectScene에 마왕 개입 UI 추가
- 경로 선택 화면에서 "마왕 개입" 버튼 표시
- 마왕 개입 활성화 시:
  - 특정 엣지를 강조 표시 (용사가 선택하도록 유도)
  - 특정 엣지를 희미하게 표시 (용사가 기피하도록 유도)
  - 강조/희미 효과는 용사 AI의 경로 선택 확률에 영향
- 마력 소모: 개입 시 마력 차감
- **수락 기준**: 마왕 개입 버튼 클릭 → 엣지 강조/희미 토글 가능 → 마력 차감

**TODO 9.2**: 진로 수정의 의심 수치 영향
- 진로 수정 사용 시 의심 수치 상승
- 의심 상승량은 개입 강도에 비례:
  - 단순 강조: 의심 +3
  - 단순 희미: 의심 +3
  - 강조 + 희미 동시: 의심 +5
- **수락 기준**: 진로 수정 시 SuspicionManager에 의심 수치 반영

**TODO 9.3**: 용사 AI 경로 선택 로직
- 기본 경로 선택: 균등 확률
- 마왕 강조 적용 시: 강조된 엣지 선택 확률 증가 (가중치 기반)
- 마왕 희미 적용 시: 희미한 엣지 선택 확률 감소
- 단일 경로일 때는 개입 불가 (선택의 여지가 없으므로)
- **수락 기준**: 마왕 개입에 따라 용사의 경로 선택 확률이 변동됨

**커밋**: `feat(path): 마왕 진로 수정 기능 구현 (경로 개입 및 의심 영향)`

---

### Phase 10: 마안(魔眼) - 전투 예측 타임라인 시스템

**목표**: 마왕의 고유 능력 '마안'을 구현. 전투의 미래 행동을 예측하여 타임라인으로 시각화하고, 마왕의 개입 카드를 타임라인에 전략적으로 삽입하는 핵심 전투 메커니즘.

**설계 배경**:
- 기존 전투 시스템은 단순 턴 순환(마왕 → 용사 → 적)으로 진행
- 마안 시스템은 전체 전투 흐름을 **미리 예측**하여 보여주고, 마왕이 **정확한 시점에 개입**할 수 있게 함
- 단순히 카드를 쓰는 것이 아니라 **"언제" 개입하느냐**가 핵심 전략이 됨
- 카드 타입에 따라 삽입/전역/조작 등 다양한 타임라인 상호작용 제공

**아키텍처 변경**:
- **Before**: DEMON_LORD_TURN에서 카드를 즉시 사용 → 효과 즉시 적용
- **After**: DEMON_LORD_TURN에서 마안 타임라인을 확인 → 카드를 타임라인 특정 위치에 삽입 → 전투가 타임라인 순서대로 실행

**턴 구조 변경**:
```
기존: [마왕턴(카드즉시사용)] → [용사턴] → [적턴] → 반복

변경: [마왕턴(마안으로 예측 확인 + 카드를 타임라인에 배치)] → [실행 페이즈(타임라인 순서대로 자동 실행)] → 반복
```

**파일 목록**:
- `src/combat/prediction_engine.lua` - 예측 엔진 (NEW)
- `src/combat/predicted_action.lua` - 예측된 행동 데이터 (NEW)
- `src/combat/timeline_manager.lua` - 타임라인 조작 관리 (NEW)
- `src/ui/timeline_ui.lua` - 타임라인 시각화 위젯 (NEW)
- `src/combat/combat_manager.lua` - (수정) 예측 시스템 통합
- `src/combat/turn_manager.lua` - (수정) 실행 페이즈 추가
- `src/handler/combat_handler.lua` - (수정) 타임라인 UI 통합
- `src/card/card.lua` - (수정) 카드 타임라인 타입 추가
- `src/card/card_effect.lua` - (수정) 전역/조작 효과 타입 추가
- `data/cards/base_cards.lua` - (수정) 카드 데이터에 timeline_type 필드 추가

**TODO 10.1**: PredictedAction 데이터 클래스 구현
- 속성:
  - actor: Entity (행동 주체 - 용사 또는 적)
  - action_type: string ("attack", "defend", "skill")
  - target: Entity|nil (행동 대상)
  - value: number (예상 데미지/회복량 등)
  - source_type: string ("hero", "enemy", "intervention")
  - card: Card|nil (개입 카드인 경우 참조)
  - description: string (UI 표시용 설명)
  - icon_type: string (UI 아이콘 식별자)
- 메서드: get_actor(), get_type(), get_target(), get_value(), is_intervention(), get_description()
- **수락 기준**: PredictedAction 인스턴스 생성 및 속성 접근 가능

**TODO 10.2**: PredictionEngine 구현
- 핵심 기능: 용사/적의 행동 패턴을 기반으로 미래 N턴의 전투 흐름을 시뮬레이션
- 메서드:
  - `generate_timeline(hero, enemies, max_turns)`:
    - Hero의 행동 패턴(현재는 attack 고정)과 Enemy의 action_patterns를 읽음
    - 각 턴마다 용사 행동 → 적 행동 순서로 PredictedAction 배열 생성
    - 적이 여럿이면 각각의 행동이 개별 PredictedAction으로 생성됨
    - 예측 시 체력 변화도 시뮬레이션하여 중도 사망(예측 기준) 반영
  - `recalculate(timeline_actions)`:
    - 마왕 개입 카드가 삽입된 후의 타임라인을 재계산
    - 삽입된 카드 효과가 이후 행동들의 결과에 영향을 미침
    - 예: 중간에 힐 카드 삽입 → 이후 예측 HP가 변동 → 사망 예측 시점 변경
  - `get_timeline()`: 현재 예측된 타임라인(PredictedAction[]) 반환
- 시뮬레이션 깊이: 기본 5턴 (설정 가능)
- **수락 기준**: Hero와 Enemy 데이터를 입력하면 유효한 PredictedAction 배열이 생성됨. 카드 삽입 후 recalculate 시 결과가 올바르게 변동됨

**TODO 10.3**: TimelineManager 구현
- 타임라인에 대한 모든 조작을 관리하는 컨트롤러
- 속성:
  - actions: PredictedAction[] (현재 타임라인)
  - prediction_engine: PredictionEngine (참조)
  - insertions: table[] (삽입된 개입 목록)
- 메서드:
  - `set_timeline(actions)`: 초기 타임라인 설정
  - `insert_at(index, card)`:
    - 타임라인 특정 위치에 개입 카드 삽입
    - 카드의 timeline_type이 "insert"인 경우만 허용
    - 삽입 후 PredictionEngine:recalculate() 호출
  - `swap(index_a, index_b)`:
    - 두 행동의 순서를 교환 (조작형 카드용)
    - 교환 후 recalculate()
  - `remove_at(index)`:
    - 특정 행동을 타임라인에서 제거 (조작형 카드용)
    - 제거 후 recalculate()
  - `apply_global(card)`:
    - 전역형 카드 적용. 위치 무관하게 전체 타임라인에 영향
    - 적용 후 recalculate()
  - `get_actions()`: 현재 타임라인 반환
  - `get_insertion_slots()`: 삽입 가능한 위치 인덱스 목록 반환
  - `confirm()`: 현재 타임라인을 확정하고 실행 큐에 전달
  - `reset()`: 모든 개입을 취소하고 원래 예측으로 복원
- **수락 기준**: insert_at, swap, remove_at, apply_global 모두 정상 동작. 각 조작 후 타임라인이 재계산됨

**TODO 10.4**: Card 클래스 수정 - 타임라인 타입 추가
- Card에 `timeline_type` 필드 추가:
  - `"insert"`: 타임라인 특정 위치에 삽입 (기본값)
  - `"global"`: 전역 적용, 위치 선택 불필요
  - `"manipulate_swap"`: 두 행동의 순서를 교환
  - `"manipulate_remove"`: 특정 행동을 제거
  - `"manipulate_delay"`: 특정 행동을 뒤로 밀어냄
- 기존 카드들은 timeline_type = "insert"로 기본 설정
- **수락 기준**: Card에 timeline_type 속성이 존재하고 올바른 값 반환

**TODO 10.5**: CardEffect 확장 - 전역/조작 효과 추가
- 새 효과 팩토리 함수:
  - `CardEffect.global_buff(stat, amount)`: 전역 공격력/방어력 변동
  - `CardEffect.swap()`: 두 행동 순서 교환 (타임라인 조작)
  - `CardEffect.nullify()`: 행동 무효화 (타임라인에서 제거)
  - `CardEffect.delay(turns)`: 행동 지연 (타임라인 뒤로 이동)
- **수락 기준**: 각 효과가 TimelineManager를 통해 타임라인에 올바르게 적용됨

**TODO 10.6**: TimelineUI 위젯 구현
- UIElement 상속
- 배치: 화면 중앙 상단 (y: 약 120~180, 게이지 아래, 캐릭터 위)
- 표시 형태: 가로 배열된 네모 박스들
- 각 박스:
  - 크기: 60x45 (또는 내용에 따라 조절)
  - 색상: 용사 행동 = 파란 계열, 적 행동 = 빨간 계열, 마왕 개입 = 보라 계열
  - 아이콘/텍스트: 행동 타입 (검 아이콘 = 공격, 방패 = 방어 등)
  - 예측 수치 표시 (데미지/힐 양)
- 인터랙션:
  - hover: 박스 확대 + 상세 정보 툴팁
  - 카드 드래그 모드: 삽입 가능 슬롯이 박스 사이에 하이라이트됨
  - 삽입 슬롯 클릭: 해당 위치에 카드 삽입
  - 조작형 카드 모드: 행동 박스를 직접 클릭하여 대상 선택
- 가로 스크롤: 타임라인이 화면 너비를 초과하면 좌우 스크롤 지원
- 메서드:
  - `set_timeline(actions)`: 타임라인 데이터 설정
  - `set_drag_mode(card)`: 카드 삽입 모드 진입 (삽입 슬롯 표시)
  - `set_manipulate_mode(card)`: 조작 모드 진입 (대상 행동 선택)
  - `cancel_mode()`: 모드 취소
  - `update(dt)`, `draw()`, `mousepressed(x,y,btn)`, `mousemoved(x,y)`
- **수락 기준**: 타임라인이 네모 박스 배열로 표시됨. 카드 드래그 시 삽입 슬롯 하이라이트. 클릭으로 삽입 완료

**TODO 10.7**: TurnManager 수정 - 실행 페이즈 추가
- 기존 페이즈: DEMON_LORD_TURN → HERO_TURN → ENEMY_TURN
- 변경된 페이즈: PLANNING_PHASE → EXECUTION_PHASE
  - `PLANNING_PHASE`: 마왕이 마안 타임라인을 보고 카드를 배치하는 단계
  - `EXECUTION_PHASE`: 확정된 타임라인이 순서대로 자동 실행되는 단계
- 실행 페이즈에서는 타임라인의 PredictedAction을 하나씩 꺼내 실행
  - 각 행동 실행 시 짧은 애니메이션 딜레이 (0.5초)
  - 마왕 개입 카드 실행 시 별도 연출 (보라색 이펙트)
- 1라운드 = PLANNING + EXECUTION 1세트
- **수락 기준**: 페이즈가 PLANNING → EXECUTION으로 정상 순환. EXECUTION에서 타임라인 순서대로 행동 실행

**TODO 10.8**: CombatManager 수정 - 예측 시스템 통합
- start_combat 시 PredictionEngine, TimelineManager 인스턴스 생성
- PLANNING_PHASE 시작 시:
  - PredictionEngine:generate_timeline() 호출
  - TimelineManager에 초기 타임라인 설정
- EXECUTION_PHASE 시작 시:
  - TimelineManager:confirm()으로 확정된 타임라인을 ActionQueue에 변환
  - ActionQueue에서 순서대로 실행
- 전투 종료 조건: 실행 중 용사/적 사망 시 즉시 종료
- **수락 기준**: 전투가 예측 → 계획 → 실행 루프로 정상 진행

**TODO 10.9**: CombatHandler 수정 - 타임라인 UI 통합
- TimelineUI 위젯 추가 (화면 상단 중앙)
- PLANNING_PHASE에서:
  - TimelineUI에 예측 타임라인 표시
  - CardHand에서 카드 선택 → TimelineUI에서 삽입 위치 선택
  - 카드 timeline_type에 따라 UI 모드 자동 전환
  - "턴 종료" 버튼 → TimelineManager:confirm() → EXECUTION_PHASE 전환
  - "리셋" 버튼 → TimelineManager:reset() → 개입 취소
- EXECUTION_PHASE에서:
  - TimelineUI에서 현재 실행 중인 행동을 하이라이트
  - 각 행동 실행 시 해당 박스가 강조 + 페이드 아웃
- **수락 기준**: 마왕 턴에 타임라인 표시 + 카드 삽입 가능. 실행 시 진행 상황 시각화

**TODO 10.10**: 카드 데이터 업데이트
- 기존 카드들에 `timeline_type = "insert"` 추가
- 새 카드 추가:
  - `"time_warp"` (조작형): 두 행동 순서 교환, cost 2, suspicion +8
  - `"nullify"` (조작형): 적 행동 하나 제거, cost 3, suspicion +12
  - `"delay_strike"` (조작형): 적 행동을 2턴 뒤로 밀기, cost 1, suspicion +5
  - `"chaos_field"` (전역형): 모든 적 공격력 -2, cost 2, suspicion +7
  - `"dark_blessing"` (전역형): 용사 방어력 +3 (전체 전투), cost 1, suspicion +4
- **수락 기준**: 카드 데이터 파일에서 모든 카드 로딩 가능. timeline_type 속성이 올바르게 설정됨

**커밋 1**: `feat(combat): 마안 예측 엔진 및 타임라인 데이터 구조 구현`
**커밋 2**: `feat(combat): TimelineManager 타임라인 조작 시스템 구현`
**커밋 3**: `feat(ui): TimelineUI 예측 타임라인 시각화 위젯 구현`
**커밋 4**: `feat(combat): 전투 시스템에 마안 예측 통합 (CombatManager, TurnManager)`
**커밋 5**: `feat(card): 전역/조작형 카드 타입 및 데이터 추가`

---

## 8. Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| **Lua OOP 복잡도** | 중 | 중 | middleclass 라이브러리로 표준화. 복잡한 다중 상속 회피, 단일 상속 + composition 선호 |
| **맵 생성 알고리즘 품질** | 높 | 중 | 초기에는 단순 알고리즘 사용 (열 기반 배치). 연결성 검증 로직 필수. 나중에 개선 |
| **Love2D Scene 스택 성능** | 낮 | 낮 | 스택 깊이 최대 3~4 수준. 비활성 Scene은 update 스킵 |
| **UI 시스템 자체 구현 부담** | 중 | 중 | 최소한의 위젯만 구현. 복잡한 레이아웃은 Phase 후반으로 미룸 |
| **전투 밸런스** | 높 | 낮 | 이번 범위에서는 밸런싱 제외. 테스트용 수치만 사용 |
| **카드 효과 조합 복잡도** | 중 | 중 | Strategy 패턴으로 효과 분리. 초기에는 단순 효과만 구현 |
| **애니메이션 타이밍 이슈** | 중 | 낮 | flux tween 라이브러리의 완료 콜백으로 동기화. 강제 스킵 옵션 제공 |
| **예측 시뮬레이션 성능** | 중 | 중 | 시뮬레이션 깊이를 5턴으로 제한. 재계산은 카드 삽입 시에만 수행 |
| **타임라인 UI 복잡도** | 높 | 중 | 단계적 구현: 먼저 삽입형만 구현 → 조작형 추가. 드래그 앤 드롭 대신 클릭 기반 인터랙션으로 시작 |
| **예측 정확도와 실행 불일치** | 중 | 높 | 예측은 결정론적 패턴 기반으로 수행. 랜덤 요소는 시드 기반으로 일관성 보장 |

---

## 9. Documentation Updates (GAME_CONCEPT.md)

### 추가할 섹션: "UI/UX 디자인"

```markdown
## UI/UX 디자인

### 화면 레이아웃 (1280x720)

**메인 게임 화면 (MapScene)**:
┌─────────────────────────────────────────┐
│ [의심 게이지]  [마력 게이지]  [미니맵]  │
│                                         │
│                                         │
│     ← 배경 스크롤 ←                    │
│          [용사]  →  [다음 노드]         │
│                                         │
│                                         │
│              [카드 패 (전투 중)]         │
└─────────────────────────────────────────┘

**전투 화면 (CombatScene)**:
┌─────────────────────────────────────────┐
│ [의심 게이지]              [마력 게이지] │
│                                         │
│  [용사]                      [적 1]     │
│  [HP 게이지]                 [HP 게이지] │
│                              [적 2]     │
│                              [HP 게이지] │
│                                         │
│  [카드1] [카드2] [카드3] [패스] [턴종료] │
└─────────────────────────────────────────┘

**경로 선택 (EdgeSelectScene)**:
┌─────────────────────────────────────────┐
│         "다음 경로를 선택하세요"         │
│                                         │
│     ┌─[전투]──→ 노드 A                 │
│     │                                   │
│  현재 ─[이벤트]──→ 노드 B              │
│     │                                   │
│     └─[전투]──→ 노드 C                 │
│                                         │
└─────────────────────────────────────────┘
```

### 추가할 섹션: "기술 아키텍처"

```markdown
## 기술 아키텍처

### 핵심 기술 스택
- **엔진**: Love2D (Lua)
- **OOP**: middleclass 라이브러리
- **애니메이션**: flux (tween)
- **유틸리티**: lume

### 아키텍처 원칙
- Scene 기반 화면 관리 (State Machine + Stack)
- EventBus를 통한 시스템 간 느슨한 결합
- Strategy 패턴으로 카드 효과 확장
- Factory 패턴으로 맵 생성
- Data-driven 설계 (Lua 테이블 기반 데이터 파일)

### 디렉토리 구조
- `src/core/` - 프레임워크 (Game, SceneManager, EventBus)
- `src/map/` - 맵 시스템 (Node, Edge, Floor, MapGenerator)
- `src/combat/` - 전투 시스템 (Entity, Hero, Enemy, TurnManager)
- `src/card/` - 카드/개입 시스템 (Card, Deck, Mana, Suspicion)
- `src/event/` - 이벤트 시스템 (Event, Choice, EventManager)
- `src/scene/` - Scene 구현 (MapScene, CombatScene 등)
- `src/ui/` - UI 위젯 (Button, Gauge, Minimap 등)
- `src/anim/` - 애니메이션 (Camera, Transition)
- `data/` - 게임 데이터 정의
- `assets/` - 아트/사운드 에셋
```

---

## 10. Success Criteria

### Phase 완료 기준 (전체)

1. Love2D 실행 시 에러 없이 게임 시작
2. 맵이 절차적으로 생성되고 그래프 구조가 유효함
3. GameScene이 페이즈 상태 머신으로 게임플레이 흐름 제어
4. 노드 간 이동 시 벨트스크롤 애니메이션 재생 (flux 기반)
5. 전투 노드에서 CombatHandler가 턴제 전투 진행
6. 이벤트 노드에서 EventHandler가 선택지 이벤트 진행
7. 마왕 카드 사용 시 효과 적용 및 의심 수치 변동
8. 의심 수치 MAX 도달 시 게임오버
9. 전체 맵과 미니맵으로 현재 위치 확인 가능
10. 1개 층 전체 플레이 가능
11. 마왕이 경로 선택에 개입(진로 수정)할 수 있고 의심 수치에 반영됨
12. GameScene의 페이즈 전환 시 flux 기반 fade/전환 효과 재생
13. 마안 예측 타임라인이 전투 시작 시 정상 생성되고 UI에 표시됨
14. 삽입형 카드를 타임라인 특정 위치에 끼워넣을 수 있고 재계산됨
15. 전역형 카드가 위치 무관하게 전체 타임라인에 영향을 미침
16. 조작형 카드로 행동 순서 교환/제거/지연이 가능함
17. PLANNING → EXECUTION 페이즈 순환이 정상 동작함

### 아키텍처 개선 검증

1. **GameScene 페이즈 통합**: 4개의 독립 Scene 대신 1개의 GameScene + 3개의 Handlers로 통합
   - 페이즈 전환이 명확한 상태 머신으로 구현됨
   - Handler는 Scene이 아닌 모듈로 캡슐화됨 (SceneManager 스택 불필요)
   - EventBus를 통한 느슨한 결합 유지

2. **Animation 시스템 통합**: 별도 Transition 클래스 제거, flux 기반 통합
   - 모든 애니메이션 (이동, 페이드, shake)이 flux tween으로 처리됨
   - Game:update(dt)에서 flux.update(dt) 호출하여 중앙 관리
   - Camera는 apply/release로 변환 상태 제어

3. **MapScene 별도 유지**: GameScene과 독립적인 맵 탐색 전용 Scene
   - 이벤트 중단 시 맵으로 복귀하는 전환이 깔끔함
   - MapOverlay와 MapScene이 SceneManager 스택으로 독립 관리

### 코드 품질 기준

1. 모든 클래스/모듈이 단일 책임 원칙 준수
2. 새 노드 타입 추가 시 기존 코드 수정 불필요 (개방-폐쇄 원칙)
3. 새 카드 효과 추가 시 Card 클래스 수정 불필요 (Strategy 패턴)
4. 시스템 간 직接 참조 최소화 (EventBus 활용)
5. Lua 코딩 규칙 준수 (snake_case, 2 spaces 들여쓰기)
6. Handler 모듈들이 SceneManager에 의존하지 않음 (GameScene에서만 관리)
