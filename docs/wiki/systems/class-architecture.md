# Class Architecture

이 문서는 현재 코드 기준 클래스 구조를 요약합니다.

## 1) 상위 구성도

```mermaid
flowchart LR
  A[main.lua] --> B[Game Singleton]
  B --> C[SceneManager]
  C --> D[MainMenuScene]
  C --> E[GameScene]
  C --> F[RunEndScene]

  E --> G[Map System]
  E --> H[Combat Handler]
  E --> I[Event Handler]
  E --> J[Reward Handler]
  E --> K[UI Widgets]
  E --> L[RunContext/RNG]
  E --> M[RunSaveCoordinator]

  H --> N[CombatManager]
  N --> O[TurnManager]
  N --> P[TimelineManager]
  N --> Q[PredictionEngine]

  E --> R[RewardManager]
  E --> S[EventManager]
  E --> T[SpellBook]
  E --> U[SuspicionManager]
  E --> V[ManaManager]
```

## 2) Core / Scene 계층

```mermaid
classDiagram
  class Game {
    +getInstance()
    +init()
    +update(dt)
    +draw()
  }

  class SceneManager {
    +push(scene)
    +pop()
    +switch(scene)
    +peek()
  }

  class Scene {
    +enter(params)
    +exit()
    +update(dt)
    +draw()
  }

  class MainMenuScene
  class GameScene {
    -phase
    -run_seed
    -run_context
    -save_coordinator
  }
  class RunEndScene

  Game --> SceneManager
  SceneManager --> Scene
  MainMenuScene --|> Scene
  GameScene --|> Scene
  RunEndScene --|> Scene
```

## 3) 맵 시스템

```mermaid
classDiagram
  class MapGenerator
  class Map
  class Floor
  class Node
  class CombatNode
  class EventNode
  class Edge

  MapGenerator --> Map : generate_map
  Map --> Floor
  Floor --> Node
  Floor --> Edge
  CombatNode --|> Node
  EventNode --|> Node
  Edge --> Node : from/to
```

## 4) 전투/예측/상태 시스템

```mermaid
classDiagram
  class CombatHandler
  class CombatManager
  class TurnManager
  class TimelineManager
  class PredictionEngine
  class PredictedAction
  class ActionQueue
  class Entity
  class Hero
  class Enemy
  class ActionPattern
  class StatusContainer
  class StatusRegistry

  CombatHandler --> CombatManager
  CombatManager --> TurnManager
  CombatManager --> TimelineManager
  CombatManager --> PredictionEngine
  CombatManager --> ActionQueue

  TimelineManager --> PredictedAction
  PredictionEngine --> PredictedAction

  Hero --|> Entity
  Enemy --|> Entity
  Entity --> StatusContainer
  StatusContainer --> StatusRegistry
  Hero --> ActionPattern
  Enemy --> ActionPattern
```

상태 컨테이너 메모:

- `StatusContainer`는 상태 목록 외에 UID 인덱스와 생존 인덱스를 함께 유지합니다.
- `emit()`은 snapshot 순회와 생존 확인으로, 순회 도중 제거된 상태 hook를 다시 호출하지 않도록 설계됩니다.
- `remove()`와 `restore()`는 UID 변경/복원 이후에도 stale alias가 남지 않게 재매핑 책임을 집니다.

## 5) 주문/보상/이벤트 시스템

```mermaid
classDiagram
  class Spell
  class SpellBook
  class SpellEffect
  class ManaManager
  class SuspicionManager

  class RewardManager
  class DemonAwakening
  class LegendaryInventory
  class RewardCatalog

  class EventManager
  class Event
  class Choice

  SpellBook --> Spell
  Spell --> SpellEffect
  RewardManager --> RewardCatalog
  RewardManager --> DemonAwakening
  RewardManager --> LegendaryInventory

  EventManager --> Event
  Event --> Choice

  SpellBook --> ManaManager
  Spell --> SuspicionManager
```

## 6) 핸들러 / UI 계층

```mermaid
classDiagram
  class MainMenuScene
  class GameScene
  class RunEndScene
  class CombatHandler
  class EventHandler
  class EdgeSelectHandler
  class RewardHandler

  class UIElement
  class Gauge
  class Button
  class Panel
  class TimelineUI
  class SpellBookOverlay
  class EdgeSelector
  class Minimap
  class MapOverlay
  class SettingsOverlay
  class Camera

  CombatHandler --> TimelineUI
  CombatHandler --> SpellBookOverlay
  EventHandler --> Button
  RewardHandler --> Button
  EdgeSelectHandler --> EdgeSelector

  Gauge --|> UIElement
  Button --|> UIElement
  Panel --|> UIElement
  TimelineUI --|> UIElement
  SpellBookOverlay --|> UIElement
  EdgeSelector --|> UIElement
  Minimap --|> UIElement
  MapOverlay --|> UIElement
  SettingsOverlay --|> UIElement

  GameScene --> CombatHandler
  GameScene --> EventHandler
  GameScene --> EdgeSelectHandler
  GameScene --> RewardHandler
  GameScene --> Minimap
  GameScene --> MapOverlay
  GameScene --> SettingsOverlay
  GameScene --> Camera
```

## 7) 변경 포인트

- 씬 구조는 `GameScene` 통합형입니다.
- 개입 구조는 `Deck/Card`가 아니라 `SpellBook/Spell` 중심입니다.
- RNG는 `RunContext` 스트림 RNG를 사용합니다.
- 정산은 `RewardManager` + `DemonAwakening` + `LegendaryInventory` 큐 기반입니다.

## 출처

- 루트 호환성 포인터: [`../../../CLASS_DIAGRAM.md`](../../../CLASS_DIAGRAM.md)
