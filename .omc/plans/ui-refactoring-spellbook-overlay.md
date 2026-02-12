# UI 리팩토링: SpellBook 오버레이 & 타임라인 재배치

> **작성일:** 2026-02-13
> **대상 해상도:** 1280x720
> **엔진:** Love2D (Lua)
> **Ralplan 컨센서스:** APPROVED (Planner → Architect → Critic 3자 검토 완료)
> **Architect 판정:** APPROVE_WITH_CONDITIONS → 보완 반영 완료
> **Critic 판정:** APPROVE (조건부) → 보완 반영 완료

---

## 1. 요구사항 정리

### 1-1. 타임라인 재배치
| 항목 | 현재 | 변경 후 | 목적 |
|------|------|---------|------|
| 위치 | y=10 (화면 최상단) | y=140 (모드 텍스트 아래) | 모드 텍스트와의 시각적 연결성 확보 |
| max_visible | 18개 | 15개 | 화면 중앙 영역과의 겹침 방지, 좌측 오버레이 공간 확보 |
| 모드 텍스트 | box_height+50 (y~110) 에 렌더링 | y=120 고정 | 타임라인 바로 위에 위치하여 맥락 명확화 |

**효과:** 모드 텍스트 → 타임라인 → 툴팁이 자연스러운 수직 흐름을 형성한다.

### 1-2. SpellBook 오버레이 (SpellPanel 대체)
| 항목 | 현재 | 변경 후 | 목적 |
|------|------|---------|------|
| UI 형태 | 하단 가로 카드 나열 (120x160 각) | 좌측 세로 패널 오버레이 | 마법 수 증가에 대응하는 스케일링 |
| 위치 | 화면 하단 중앙 | 좌측 영역 (x=0~280) | 좌측 게이지 영역과 통합 |
| 필터 | 없음 | All / Insert / Manipulate / Global 탭 | 마법 타입별 빠른 탐색 |
| 상태 표시 | 카드 위 오버레이 텍스트 | 리스트 항목 내 인라인 상태 | 한눈에 사용가능/사용됨/예약됨 파악 |

**효과:** 마법이 15개, 20개, 30개로 늘어도 스크롤로 자연스럽게 대응. 탭 필터로 원하는 타입을 즉시 찾을 수 있다.

### 1-3. 게이지 통합
| 항목 | 현재 | 변경 후 | 목적 |
|------|------|---------|------|
| Suspicion 게이지 | GameScene에서 (20,20) 위치에 독립 렌더링 | SpellBookOverlay 상단에 통합 | 좌측 패널을 정보 허브로 통합 |
| Mana 게이지 | GameScene에서 (20,60) 위치에 독립 렌더링 | SpellBookOverlay 상단에 통합 | 마법 사용 시 마나 변화를 바로 옆에서 확인 |
| Hero HP 텍스트 | GameScene에서 (20,100) 위치에 텍스트 렌더링 | SpellBookOverlay 상단에 통합 | 관련 정보 집약 |

---

## 2. 새 UI 레이아웃 설계

### 2-1. 전체 레이아웃 (1280x720)

```
 0                    280                                              1280
 +---------------------+------------------------------------------------+
 |                     |                                                | 0
 | [SpellBookOverlay]  |        (모드 텍스트 영역, y=120)                |
 |                     |                                                |
 | +-Suspicion Bar---+ |   [====== 타임라인 박스들 (y=140) ======]       | 140
 | | ####........... | |   [50x60] [50x60] [50x60] ... (최대15개)       |
 | +-Mana Bar-------+ |                                                | 200
 | | ####........... | |   (의심도 미리보기 / 스크롤 인디케이터)          |
 | +-Hero HP--------+ |   (호버 툴팁, y~220)                            |
 | | HP: 80/100     | |                                                | 240
 | +--Tab Bar-------+ |                                                |
 | |All|Ins|Man|Glb | |                                                |
 | +----------------+ |                                                |
 | +-Spell List-----+ |                                                |
 | | [*] Light Heal  | |         [적 캐릭터 영역]                       |
 | |    15 mana +5sus| |          (enemy_world_x, enemy_world_y)       |
 | |                 | |                                                |
 | | [*] Heavy Heal  | |                                                |
 | |    25 mana +10  | |                                                |
 | |                 | |                                                |
 | | [ ] Divine Strk | |                                                |
 | |    20 mana +8   | |                                                |
 | |    (used)       | |                                                |
 | |                 | |                                                |
 | | ... (scroll)    | |                                                |
 | |                 | |                                                |
 | +-----------------+ |                                                |
 |                     |    [Hero Gauge]     [Enemy Gauge(s)]           |
 |  [Confirm] [Reset]  |    (50,520)          (800,460+)               |
 +---------------------+------------------------------------------------+
 |                           Phase: COMBAT                              | 700
 +----------------------------------------------------------------------+ 720
```

### 2-2. SpellBookOverlay 세부 구조

```
 x=10, y=10
 +-- SpellBookOverlay (260 x 690) --+
 |                                   |
 | +-- Status Section (260 x 110) -+ | y=10
 | | Suspicion: [######----] 45/100| | y=15,  240x22
 | | Mana:      [########--] 80/100| | y=42,  240x22
 | | Hero HP:   [########--] 80/100| | y=69,  240x22
 | | Phase: Planning Turn 1        | | y=96,  h=18
 | +-------------------------------+ |
 |                                   |
 | +-- Tab Bar (260 x 32) --------+ | y=125
 | | [All] [Insert] [Manip] [Glb] | |
 | +-------------------------------+ |
 |                                   |
 | +-- Spell List (260 x scroll) -+ | y=162
 | |                               | |
 | | +-- Spell Item (240 x 52) --+ | | item_y + 0
 | | | [mana_icon] Light Heal    | | |
 | | | 15 mana  |  susp: +5     | | |
 | | | [PLAYABLE]                | | |
 | | +---------------------------+ | |
 | |                               | |
 | | +-- Spell Item (240 x 52) --+ | | item_y + 56
 | | | [mana_icon] Heavy Heal    | | |
 | | | 25 mana  |  susp: +10    | | |
 | | | [PLAYABLE]                | | |
 | | +---------------------------+ | |
 | |                               | |
 | | ... (최대 ~9개 표시, 나머지   | |
 | |      마우스 휠 스크롤)        | |
 | |                               | |
 | +-------------------------------+ | y=662 (max)
 |                                   |
 | +-- Action Bar (260 x 36) -----+ | y=668
 | | [  Confirm  ]  [   Reset   ] | |
 | +-------------------------------+ |
 +-----------------------------------+ y=700
```

### 2-3. 컴포넌트별 정확한 좌표 및 크기

| 컴포넌트 | x | y | width | height | 비고 |
|----------|---|---|-------|--------|------|
| **SpellBookOverlay** | 10 | 10 | 260 | 690 | 전체 패널 (전투 시에만 표시) |
| Status - Suspicion | 20 | 15 | 240 | 22 | Gauge 컴포넌트 재활용 |
| Status - Mana | 20 | 42 | 240 | 22 | Gauge 컴포넌트 재활용 |
| Status - Hero HP | 20 | 69 | 240 | 22 | Gauge 컴포넌트 재활용 |
| Status - Phase Text | 20 | 96 | 240 | 18 | 텍스트 표시 |
| Tab Bar | 15 | 125 | 250 | 32 | 4개 탭 버튼 (각 ~60x32) |
| Spell List Area | 15 | 162 | 250 | 500 | 스크롤 가능 영역 |
| Spell Item | 15 | (동적) | 250 | 52 | 각 마법 항목 |
| Action Bar | 15 | 668 | 250 | 36 | Confirm + Reset 버튼 |
| **TimelineUI (수정)** | (중앙정렬) | 140 | (동적) | 60 | 15개 기준 중앙정렬, 좌측 280px 이후 |
| Mode Text | 280 | 120 | 1000 | 16 | 타임라인 바로 위 |
| Suspicion Preview | 280 | 208 | 1000 | 16 | 타임라인 바로 아래 |
| Hover Tooltip | 280 | 224 | 1000 | 16 | 미리보기 아래 |

### 2-4. 타임라인 새 위치 상세

타임라인은 좌측 오버레이 영역(280px)을 제외한 나머지 공간(280~1280, 총 1000px)에서 중앙 정렬한다.

```
timeline_area_x = 280
timeline_area_width = 1000  (1280 - 280)
max_visible = 15
box_width = 50, box_spacing = 6
total_timeline_width = 15 * (50 + 6) - 6 = 834
start_x = 280 + (1000 - 834) / 2 = 280 + 83 = 363
timeline_y = 140
```

---

## 3. 변경 파일 목록

### 신규 파일

| 파일 | 역할 |
|------|------|
| `src/ui/spell_book_overlay.lua` | SpellBookOverlay 클래스 (SpellPanel 대체) |

### 수정 파일

| 파일 | 변경 내용 |
|------|----------|
| `src/ui/timeline_ui.lua` | y좌표 변경 (10 → 140), max_visible 변경 (18 → 15), 타임라인 중앙정렬 기준 변경 (전체 1280 → 우측 1000px), 모드 텍스트/툴팁 위치 조정 |
| `src/handler/combat_handler.lua` | SpellPanel → SpellBookOverlay 교체, suspicion_manager/mana_manager를 오버레이에 전달, 좌측 게이지 통합, confirm/reset 버튼 오버레이 내장으로 이관, draw_ui()/mousepressed() 수정 |
| `src/scene/game_scene.lua` | 전투 중 기존 suspicion_gauge, mana_gauge, hero_hp 텍스트 숨김 처리 (오버레이가 대신 표시), combat_handler에 suspicion_manager 전달 방식 유지 |
| `src/spell/spell_book.lua` | `get_spells_by_type(type)` 메서드 추가 (탭 필터링용) |

### 제거 대상 (단계적)

| 파일 | 처리 |
|------|------|
| `src/ui/spell_panel.lua` | SpellBookOverlay 완성 후 삭제. CombatHandler에서의 참조 제거 |

---

## 4. SpellBookOverlay 클래스 설계

### 4-1. 클래스 구조

```lua
---@class SpellBookOverlay : UIElement
---@field spell_book SpellBook|nil
---@field mana_manager ManaManager|nil
---@field suspicion_manager SuspicionManager|nil
---@field hero Entity|nil
---@field on_play_callback function|nil      -- function(spell)
---@field on_confirm_callback function|nil   -- function()
---@field on_reset_callback function|nil     -- function()
---@field active_tab string                  -- "all"|"insert"|"manipulate"|"global"
---@field scroll_offset number
---@field hovered_spell_index number|nil
---@field max_visible_spells number
---@field panel_x number
---@field panel_y number
---@field panel_width number
---@field panel_height number
```

### 4-2. 메서드 목록

| 메서드 | 시그니처 | 역할 |
|--------|----------|------|
| `initialize` | `()` | UIElement(10, 10, 260, 690) 초기화, 내부 상태 초기화 |
| `set_spell_book` | `(spell_book: SpellBook)` | SpellBook 레퍼런스 설정 |
| `set_mana_manager` | `(mana_manager: ManaManager)` | ManaManager 레퍼런스 설정 |
| `set_suspicion_manager` | `(suspicion_manager: SuspicionManager)` | SuspicionManager 레퍼런스 설정 |
| `set_hero` | `(hero: Entity)` | Hero 레퍼런스 설정 (HP 표시용) |
| `set_on_play` | `(callback: function)` | 마법 선택 콜백 설정 |
| `set_on_confirm` | `(callback: function)` | 확인 버튼 콜백 설정 |
| `set_on_reset` | `(callback: function)` | 리셋 버튼 콜백 설정 |
| `set_active_tab` | `(tab: string)` | 탭 전환 (스크롤 오프셋 리셋) |
| `update` | `(dt: number)` | 호버 상태 갱신, 내부 버튼 업데이트 |
| `draw` | `()` | 전체 패널 렌더링 |
| `mousepressed` | `(mx, my, button)` | 탭/마법/버튼 클릭 처리 |
| `wheelmoved` | `(x, y)` | 마법 리스트 스크롤 |
| `_get_filtered_spells` | `() -> Spell[]` | active_tab에 따른 필터링된 마법 목록 반환 |
| `_get_spell_status` | `(spell: Spell) -> string` | "playable"\|"no_mana"\|"used"\|"reserved" |
| `_is_playable` | `(spell: Spell) -> boolean` | 사용 가능 여부 판정 |
| `_draw_status_section` | `()` | Suspicion/Mana/HP 게이지 렌더링 |
| `_draw_tab_bar` | `()` | 탭 버튼 렌더링 |
| `_draw_spell_list` | `()` | 마법 리스트 렌더링 (스크롤 적용) |
| `_draw_spell_item` | `(spell, index, y)` | 개별 마법 항목 렌더링 |
| `_draw_action_bar` | `()` | Confirm/Reset 버튼 렌더링 |

### 4-3. Gauge 인스턴스 관리 (Architect 보완)

Gauge 클래스 인스턴스를 `initialize`에서 절대좌표로 3개 생성한다.
SpellBookOverlay는 고정 위치(x=10, y=10)이므로 오버레이 이동 시 재계산이 불필요하다.

```lua
function SpellBookOverlay:initialize()
  UIElement.initialize(self, 10, 10, 260, 690)
  -- Gauge 인스턴스 (절대좌표)
  self.suspicion_gauge = Gauge:new(20, 15, 240, 22, "suspicion.label", {1, 0, 0})
  self.mana_gauge = Gauge:new(20, 42, 240, 22, "combat.mana_label", {0, 0.5, 1})
  self.hero_hp_gauge = Gauge:new(20, 69, 240, 22, "entity.hero", {0.2, 0.8, 0.2})
  -- ... 나머지 초기화 ...
end
```

참고: SettingsOverlay는 UIElement 비상속이나, SpellBookOverlay는 `hit_test`/`set_visible` 등의 기본 기능이 필요하므로 UIElement 상속이 더 적합하다.

### 4-4. 탭 필터링 로직

```
active_tab 값에 따른 필터 조건:
  "all"        → 모든 마법 반환
  "insert"     → spell:get_timeline_type() == "insert"
  "manipulate" → spell:get_timeline_type():sub(1,10) == "manipulate"
                  (manipulate_swap, manipulate_remove, manipulate_delay, manipulate_modify 포함)
  "global"     → spell:get_timeline_type() == "global"
```

SpellBook에 추가할 메서드:

```lua
--- 타입별 마법 필터링
---@param type_filter string "all"|"insert"|"manipulate"|"global"
---@return Spell[]
function SpellBook:get_spells_by_type(type_filter)
  if type_filter == "all" then
    return self.spells
  end
  local result = {}
  for _, spell in ipairs(self.spells) do
    local ttype = spell:get_timeline_type()
    if type_filter == "insert" and ttype == "insert" then
      table.insert(result, spell)
    elseif type_filter == "manipulate" and ttype:sub(1,10) == "manipulate" then
      table.insert(result, spell)
    elseif type_filter == "global" and ttype == "global" then
      table.insert(result, spell)
    end
  end
  return result
end
```

### 4-4. 마법 리스트 항목 레이아웃

각 마법 항목 (250 x 52):

```
+-- Spell Item (250 x 52) --------------------------------+
| [Mana Circle]  Spell Name                    [Status]   |  row 1: y+4
|   15            Light Heal                   PLAYABLE    |
|                                                          |
|  susp: +5  |  "Heal the hero for 10 HP."                |  row 2: y+24
|            |  (설명 텍스트, 가능하면 1줄 표시)              |
+------------------------------------------------------+  |  row 3: y+40 (구분선)
```

상태별 시각 표현:

| 상태 | 배경색 | 테두리색 | 텍스트 알파 | 상태 텍스트 |
|------|--------|----------|-------------|------------|
| playable | (0.2, 0.2, 0.3, 0.9) | (0.6, 0.8, 1, 1) | 1.0 | 없음 |
| no_mana | (0.15, 0.15, 0.15, 0.7) | (0.4, 0.4, 0.4, 0.6) | 0.5 | "MANA" (회색) |
| used | (0.12, 0.12, 0.12, 0.8) | (0.3, 0.3, 0.3, 0.5) | 0.4 | "USED" (어두운 회색) |
| reserved | (0.2, 0.15, 0.3, 0.9) | (0.6, 0.3, 1, 1) | 0.8 | "RESERVED" (보라) |
| hovered + playable | (0.3, 0.3, 0.5, 1.0) | (0.8, 0.9, 1, 1) | 1.0 | 없음 |

### 4-5. 마법 선택 → CombatHandler → TimelineUI 연동 흐름

```
[SpellBookOverlay]                [CombatHandler]              [TimelineUI]
      |                                |                            |
  사용자 클릭 spell item               |                            |
      |---on_play_callback(spell)----->|                            |
      |                    _on_spell_selected(spell)                |
      |                      spell:reserve(mana_manager)            |
      |                      spell_book:reserve(spell)              |
      |                                |                            |
      |                    timeline_type 판별                       |
      |                      "insert" --|--enter_insert_mode------->|
      |                      "global" --|--enter_global_mode------->|
      |                      "manip"  --|--enter_manipulate_mode--->|
      |                                |                            |
      |                                |  사용자가 타임라인 클릭      |
      |                                |<--on_insert_callback-------|
      |                                |  또는 on_manipulate_callback|
      |                                |  또는 on_global_callback   |
      |                                |                            |
```

**핵심:** 기존 `_on_spell_selected`의 `(spell, index)` 시그니처에서 `index` 파라미터는 SpellPanel 내부 인덱스였으나, 오버레이에서는 불필요. `(spell)` 만 전달하면 된다. CombatHandler 내부 로직은 spell 객체로 timeline_type을 판별하므로 변경 최소화.

### 4-6. 스크롤 처리

```
spell_list_area_y = 162
spell_list_area_height = 500  (662 - 162)
spell_item_height = 52
spell_item_spacing = 4
items_per_page = floor(500 / (52 + 4)) = 8 (안전하게 8개)

scroll_offset: 0부터 시작, max(0, filtered_count - items_per_page) 까지
wheelmoved(x, y): scroll_offset = clamp(scroll_offset - y, 0, max_scroll)

렌더링 시 love.graphics.setScissor로 클리핑 적용:

love.graphics.setScissor(15, 162, 250, 500)
-- 스펠 아이템 렌더링 ...
love.graphics.setScissor()  -- ⚠️ 반드시 해제! (코드베이스 최초 사용)
-- 해제하지 않으면 이후 모든 렌더링이 클리핑됨
```

---

## 5. TimelineUI 수정 사항

### 5-1. 새 y좌표 계산

| 요소 | 현재 y | 새 y | 계산 근거 |
|------|--------|------|----------|
| 타임라인 박스 | 10 | 140 | 모드 텍스트(y=120) 아래 20px 여백 |
| Suspicion 미리보기 | box_height+18 (=78) | 208 | 140 + 60 + 8 |
| 스크롤 인디케이터 | box_height+18 (=78, 우측정렬) | 208 | 미리보기와 같은 줄, 우측 정렬 |
| 호버 툴팁 | box_height+34 (=94) | 224 | 208 + 16 |
| 모드 힌트 텍스트 | box_height+50 (=110) | 120 | 타임라인 **위**로 이동 (핵심 변경) |

### 5-2. 중앙정렬 기준 변경

현재: 전체 화면 폭 1280px 기준 중앙정렬
변경: 좌측 오버레이(280px)를 제외한 영역(280~1280) 기준 중앙정렬

```lua
-- 현재:
local start_x = (1280 - total_width) / 2

-- 변경:
local area_x = 280
local area_width = 1000  -- 1280 - 280
local start_x = area_x + (area_width - total_width) / 2
```

### 5-3. max_visible 변경

```lua
-- 현재:
self.max_visible = 18

-- 변경:
self.max_visible = 15
-- 15 * (50 + 6) - 6 = 834px → 1000px 영역에 충분히 수용
```

### 5-4. 모드 텍스트/툴팁 위치 관계 (위→아래 순서)

```
y=120: 모드 힌트 텍스트 ("Select target action..." 등)
y=140: 타임라인 박스 상단
y=200: 타임라인 박스 하단 (140 + 60)
y=208: 의심도 미리보기 + 스크롤 인디케이터
y=224: 호버 액션 툴팁
```

### 5-5. insert_indicator y좌표 수정 (Architect/Critic 보완)

현재 `timeline_ui.lua:154`에서 삽입 인디케이터의 y좌표가 `8`로 하드코딩되어 있다.
`_get_box_rect`의 y 반환값과 무관하므로 별도 수정이 필요하다.

```lua
-- 현재 (154행):
love.graphics.rectangle("fill", ix - 2, 8, 4, self.box_height + 4, 2, 2)

-- 변경:
love.graphics.rectangle("fill", ix - 2, 138, 4, self.box_height + 4, 2, 2)
-- 138 = timeline_y(140) - 2
```

### 5-6. 텍스트 정렬 기준 변경

모든 `love.graphics.printf(..., 0, y, 1280, "center")` 호출을:
`love.graphics.printf(..., 280, y, 1000, "center")` 로 변경.
(우측 정렬인 스크롤 인디케이터도 동일하게 280~1280 범위 기준으로 변경)

---

## 6. CombatHandler 통합 변경

### 6-1. SpellPanel → SpellBookOverlay 교체

```lua
-- 제거:
local SpellPanel = require('src.ui.spell_panel')
self.spell_panel = SpellPanel:new()

-- 추가:
local SpellBookOverlay = require('src.ui.spell_book_overlay')
self.spell_book_overlay = SpellBookOverlay:new()
```

### 6-2. 콜백 연결 변경

```lua
-- 현재 (SpellPanel):
self.spell_panel:set_on_play(function(spell, index)
  self:_on_spell_selected(spell, index)
end)

-- 변경 (SpellBookOverlay):
self.spell_book_overlay:set_on_play(function(spell)
  self:_on_spell_selected(spell)
end)
self.spell_book_overlay:set_on_confirm(function()
  self:_confirm_planning()
end)
self.spell_book_overlay:set_on_reset(function()
  self:_reset_planning()
end)
```

### 6-3. _on_spell_selected 시그니처 변경

```lua
-- 현재:
function CombatHandler:_on_spell_selected(spell, index)

-- 변경:
function CombatHandler:_on_spell_selected(spell)
-- index 파라미터는 내부에서 사용하지 않으므로 제거해도 안전
```

### 6-4. start_combat에서 오버레이 초기화

```lua
function CombatHandler:start_combat(hero, enemies, spell_book, mana_manager, suspicion_manager)
  -- ... 기존 코드 ...

  -- SpellBookOverlay 초기화
  self.spell_book_overlay:set_spell_book(spell_book)
  self.spell_book_overlay:set_mana_manager(mana_manager)
  self.spell_book_overlay:set_suspicion_manager(suspicion_manager)
  self.spell_book_overlay:set_hero(hero)
end
```

### 6-5. Confirm/Reset 버튼 제거

기존 `self.confirm_button`과 `self.reset_button`은 SpellBookOverlay 내부로 이관.
CombatHandler에서 직접 생성/관리하던 Button 인스턴스 제거.

### 6-6. draw_ui 변경 (Architect/Critic 보완: 마나/Phase 중복 제거)

```lua
function CombatHandler:draw_ui()
  -- 타임라인 UI (절대 좌표)
  self.timeline_ui:draw()

  -- SpellBookOverlay (절대 좌표, ui_offset_y translate 밖)
  self.spell_book_overlay:draw()

  love.graphics.push()
  love.graphics.translate(0, self.ui_offset_y)

  -- ⚠️ 삭제: 기존 Phase info (201-209행) — SpellBookOverlay Status Section으로 이관됨
  -- ⚠️ 삭제: 기존 마나 중앙 표시 (211-218행) — SpellBookOverlay Status Section으로 이관됨

  -- Combat log (유지, x좌표 280+ 기준으로 조정)
  love.graphics.setColor(1, 1, 1, 0.7)
  local log_y = 30  -- Phase/마나 삭제로 y좌표 상향 가능
  local start_idx = math.max(1, #self.combat_log - 2)
  for i = start_idx, #self.combat_log do
    love.graphics.printf(self.combat_log[i], 280, log_y, 1000, 'center')
    log_y = log_y + 18
  end

  -- Hero gauge, Enemy gauges (기존 유지)
  self.hero_gauge:draw()
  for _, g in ipairs(self.enemy_gauges) do g:draw() end

  -- spell_panel:draw() 제거
  -- confirm_button:draw(), reset_button:draw() 제거

  love.graphics.pop()
end
```

### 6-7. mousepressed 변경 (Architect/Critic 보완: 이벤트 전파 차단)

```lua
function CombatHandler:mousepressed(x, y, button)
  if not self.active then return end

  -- SpellBookOverlay (절대 좌표) — 반환값으로 이벤트 전파 차단
  if self.spell_book_overlay:mousepressed(x, y, button) then return end

  -- Timeline UI (절대 좌표) — 이미 return true/false 패턴 사용 중
  if self.timeline_ui:mousepressed(x, y, button) then return end

  -- 기존 adjusted_y 로직에서 spell_panel, confirm_button, reset_button 제거
end
```

### 6-8. wheelmoved 변경 (Architect/Critic 보완: 마우스 위치 기반 라우팅)

```lua
function CombatHandler:wheelmoved(x, y)
  if not self.active then return end
  -- ⚠️ Love2D의 wheelmoved(x, y)에서 x, y는 스크롤 방향값이지 마우스 좌표가 아님!
  -- 마우스 좌표는 별도 취득 필요
  local mx, my = love.mouse.getPosition()
  if self.spell_book_overlay.visible and self.spell_book_overlay:hit_test(mx, my) then
    self.spell_book_overlay:wheelmoved(x, y)
  else
    self.timeline_ui:wheelmoved(x, y)
  end
end
```

### 6-9. _start_planning 변경 (Critic 보완: 구체적 교체 스니펫)

```lua
function CombatHandler:_start_planning()
  -- ... 기존 코드 (spell_book:start_planning, timeline setup) ...

  -- 삭제:
  -- self.spell_panel:set_spell_book(self.spell_book)
  -- self.spell_panel:set_mana_manager(self.mana_manager)
  -- self.spell_panel:set_visible(true)
  -- self.confirm_button:set_visible(true)
  -- self.reset_button:set_visible(true)

  -- 추가:
  self.spell_book_overlay:set_visible(true)
  self.timeline_ui:set_visible(true)
end
```

### 6-10. _confirm_planning 변경 (Critic 보완)

```lua
function CombatHandler:_confirm_planning()
  self.spell_book:confirm()
  -- ... timeline confirm ...

  -- 삭제:
  -- self.spell_panel:set_visible(false)
  -- self.confirm_button:set_visible(false)
  -- self.reset_button:set_visible(false)

  -- 추가:
  self.spell_book_overlay:set_visible(false)

  self.combat_manager:start_execution()
  -- ...
end
```

### 6-11. update 변경 (Critic 보완)

```lua
function CombatHandler:update(dt)
  -- ...
  -- 삭제:
  -- self.spell_panel:update(dt)
  -- self.confirm_button:update(dt)
  -- self.reset_button:update(dt)

  -- 추가:
  self.spell_book_overlay:update(dt)
  self.timeline_ui:update(dt)
  -- ...
end
```

### 6-12. deactivate 변경 (Critic 보완)

```lua
function CombatHandler:deactivate()
  self.active = false
  -- 삭제:
  -- self.spell_panel:set_visible(false)
  -- self.confirm_button:set_visible(false)
  -- self.reset_button:set_visible(false)

  -- 추가:
  self.spell_book_overlay:set_visible(false)
  self.timeline_ui:set_visible(false)
end
```

### 6-13. GameScene 측 변경

전투 중에는 기존 `suspicion_gauge`, `mana_gauge`, hero HP 텍스트를 숨겨야 한다
(SpellBookOverlay가 같은 정보를 표시하므로 중복 방지).

```lua
function GameScene:_draw_ui()
  -- 전투 중이 아닐 때만 좌측 게이지 표시
  if self.phase ~= COMBAT and self.phase ~= ENTERING_COMBAT and self.phase ~= EXITING_COMBAT then
    self.suspicion_gauge:draw()
    self.mana_gauge:draw()
    -- hero HP 텍스트 ...
  end

  self.minimap:draw()  -- 미니맵은 항상 표시 (우측 상단이므로 충돌 없음)
  -- ... 나머지 기존 코드 ...
end
```

---

## 7. 구현 순서 (Step-by-step)

### Step 1: SpellBook 필터 메서드 추가
- **파일:** `src/spell/spell_book.lua`
- **변경:** `get_spells_by_type(type_filter)` 메서드 추가
- **검증:** 각 타입별 필터링 결과가 정확한지 (insert 8개, manipulate 5개, global 2개, all 15개)

### Step 2: SpellBookOverlay 클래스 생성
- **파일:** `src/ui/spell_book_overlay.lua` (신규)
- **변경:** UIElement 상속, 4-1~4-6에 명시된 필드/메서드 구현
- **의존:** Step 1 (get_spells_by_type)
- **검증:** 독립적으로 렌더링 테스트 가능 (spell_book, mana_manager 모의 객체로)

### Step 3: TimelineUI 좌표 및 정렬 수정
- **파일:** `src/ui/timeline_ui.lua`
- **변경:**
  - `_get_box_rect`: y=10 → y=140, 중앙정렬 기준 280~1280
  - `max_visible`: 18 → 15
  - `draw()`: 모든 텍스트 y좌표 및 printf 범위 조정 (섹션 5 참조)
  - `_get_insert_x`: 동일한 좌표 체계 반영
- **의존:** 없음 (독립 수정 가능)
- **검증:** 타임라인이 화면 우측 영역에 올바르게 중앙 정렬되는지, 모드 텍스트가 위에 표시되는지

### Step 4: CombatHandler 통합
- **파일:** `src/handler/combat_handler.lua`
- **변경:**
  - SpellPanel → SpellBookOverlay 교체 (require, 인스턴스 생성, 콜백)
  - Confirm/Reset 버튼 CombatHandler에서 제거 (오버레이 내장)
  - `_on_spell_selected` 시그니처에서 index 파라미터 제거
  - `start_combat`, `_start_planning`, `draw_ui`, `mousepressed`, `wheelmoved`, `update`, `deactivate`, `_confirm_planning` 수정
- **의존:** Step 2, Step 3
- **검증:** 전투 진입 시 오버레이 표시, 마법 선택 → 타임라인 연동 정상 작동

### Step 5: GameScene 게이지 숨김 처리
- **파일:** `src/scene/game_scene.lua`
- **변경:** `_draw_ui()`에서 전투 중 suspicion_gauge, mana_gauge, hero HP 숨김
- **의존:** Step 4
- **검증:** 전투 진입/진행/퇴장 시 게이지 중복 표시 없음

### Step 6: SpellPanel 정리 및 제거
- **파일:** `src/ui/spell_panel.lua` (삭제), `src/handler/combat_handler.lua` (잔여 참조 확인)
- **변경:** spell_panel.lua 파일 삭제, 모든 참조 제거 확인
- **의존:** Step 4, Step 5 완료 및 테스트 후
- **검증:** 게임 전체 플로우에서 SpellPanel 관련 에러 없음

---

## 8. 리스크 및 엣지 케이스

### 8-1. 마법 15개 이상 스크롤
- **현재 상태:** 15개 마법이 존재. "All" 탭에서 모든 마법 표시 시 8개만 보이고 7개는 스크롤 필요.
- **대응:** `love.graphics.setScissor`로 리스트 영역 클리핑. `wheelmoved` 이벤트로 스크롤. 스크롤바 시각 표시(선택).
- **향후:** 마법이 30개 이상으로 늘어도 탭 필터 + 스크롤로 대응 가능.

### 8-2. 클릭 영역 충돌 (오버레이 vs 월드)
- **문제:** SpellBookOverlay(x=10~270)가 월드의 용사 캐릭터(hero_world_x 근처)와 겹칠 수 있음.
- **대응:** SpellBookOverlay의 mousepressed가 true를 반환하면 이벤트 전파 중단. 오버레이는 전투 중에만 표시되므로 월드 클릭은 불필요(전투 중 월드 인터랙션 없음).
- **검증:** 오버레이 영역 클릭 시 타임라인이 반응하지 않는지 확인.

### 8-3. 해상도 고려
- **현재:** 고정 해상도 1280x720.
- **설계:** 모든 좌표가 절대값이므로 현재 해상도에서는 문제 없음.
- **향후:** 해상도 변경 시 SpellBookOverlay의 panel_width, 타임라인의 area_x/area_width를 비율 기반으로 전환 필요. 현 시점에서는 과도 설계 방지를 위해 절대값 유지.

### 8-4. 기존 SpellPanel 제거 시 영향
- **직접 참조:** CombatHandler에서만 `require` 및 인스턴스 생성.
- **간접 참조:** 없음 (SpellPanel은 다른 파일에서 import되지 않음).
- **안전 전략:** Step 6에서 SpellPanel을 삭제하기 전, Step 4에서 CombatHandler의 모든 SpellPanel 참조를 SpellBookOverlay로 교체. 삭제 후 `grep -r "spell_panel\|SpellPanel"` 으로 잔여 참조 확인.

### 8-5. ui_offset_y 애니메이션과의 호환
- **현재:** CombatHandler.draw_ui()에서 `love.graphics.translate(0, self.ui_offset_y)` 적용. SpellPanel은 이 translate 내부에서 그려짐.
- **변경:** SpellBookOverlay는 translate **외부**에서 그려야 함 (절대 좌표 사용). 이는 TimelineUI와 동일한 패턴.
- **주의:** `mousepressed`에서도 SpellBookOverlay는 `adjusted_y`가 아닌 원래 `y`를 사용해야 함.

### 8-6. 전투 진입/퇴장 애니메이션
- **현재:** `ui_offset_y`가 200 → 0 으로 애니메이션되며 UI가 슬라이드 인.
- **변경:** SpellBookOverlay는 별도의 진입 애니메이션 필요 (좌측에서 슬라이드 인, 또는 페이드 인). 또는 ui_offset_y와 독립적으로 alpha 애니메이션.
- **권장:** 초기 구현에서는 visible 토글만으로 처리. 애니메이션은 후속 과제.

### 8-7. 탭 전환 시 스크롤 리셋
- **문제:** 탭을 전환하면 필터된 마법 수가 달라지므로 scroll_offset이 범위를 벗어날 수 있음.
- **대응:** `set_active_tab()` 호출 시 `scroll_offset = 0` 리셋.

### 8-8. 전투 중 마나/의심도 실시간 갱신
- **현재:** GameScene에서 매 프레임 suspicion_gauge:set_value() 호출.
- **변경:** SpellBookOverlay가 mana_manager, suspicion_manager 레퍼런스를 직접 보유하므로, draw() 시점에 매번 최신 값을 읽어 렌더링. 별도의 set_value 호출 불필요.

---

## 부록: 현재 마법 분류 (참고용)

| timeline_type | 마법 ID | 이름 | 마나 | 의심도 |
|---------------|---------|------|------|--------|
| insert | heal_light | Light Heal | 15 | +5 |
| insert | heal_heavy | Heavy Heal | 25 | +10 |
| insert | divine_strike | Divine Strike | 20 | +8 |
| insert | war_cry | War Cry | 15 | +6 |
| insert | stumble | Stumble | 0 | -8 |
| insert | weaken_foe | Weaken Foe | 12 | +3 |
| insert | dark_pact | Dark Pact | 10 | -15 |
| insert | minor_heal | Minor Heal | 0 | +3 |
| manipulate_swap | time_warp | Time Warp | 20 | +8 |
| manipulate_remove | nullify | Nullify | 30 | +12 |
| manipulate_delay | delay_strike | Delay Strike | 12 | +5 |
| manipulate_modify | weaken_blow | Weaken Blow | 12 | +4 |
| manipulate_modify | empower_strike | Empower Strike | 20 | +7 |
| global | chaos_field | Chaos Field | 25 | +7 |
| global | dark_blessing | Dark Blessing | 15 | +4 |
