# Plan: GameScene 맵 렌더링 제거 + 미니맵/맵 오버레이 구현

## 문제 분석

현재 `GameScene:_draw_world()` (game_scene.lua:148-202)에서 **전체 Node-Edge 그래프를 월드 좌표계에 직접 렌더링**하고 있음. 이로 인해 노드와 엣지가 카메라를 따라 배경처럼 항상 보이는 문제가 있음.

### 현재 렌더링 파이프라인 (문제)
```
GameScene:draw()
├─ camera:apply()
│  └─ _draw_world()
│     ├─ ★ 엣지 전체 그리기 (회색 선)     ← 제거 대상
│     ├─ ★ 노드 전체 그리기 (컬러 원)     ← 제거 대상
│     ├─ 용사 그리기 (금색 원)             ← 유지
│     └─ handler:draw_world() (전투/이벤트) ← 유지
├─ camera:release()
├─ overlay_alpha (어둠 오버레이)
└─ _draw_ui()
   ├─ 게이지들
   ├─ 미니맵 버튼 (placeholder)           ← 미니맵 위젯으로 교체
   └─ handler:draw_ui()
```

### 목표 렌더링 파이프라인
```
GameScene:draw()
├─ camera:apply()
│  └─ _draw_world()
│     ├─ 용사 그리기 (금색 원)             ← 유지
│     └─ handler:draw_world() (전투/이벤트) ← 유지
├─ camera:release()
├─ overlay_alpha (어둠 오버레이)
├─ _draw_ui()
│  ├─ 게이지들
│  ├─ ★ Minimap 위젯 (축소 맵 그래프)    ← 신규
│  └─ handler:draw_ui()
└─ ★ MapOverlay (전체 맵 오버레이)        ← 신규 (미니맵 클릭 시)
```

---

## 구현 단계

### Step 1: GameScene에서 Node-Edge 그래프 렌더링 제거

**파일**: `src/scene/game_scene.lua`

**변경 내용**:
- `_draw_world()` 함수에서 엣지 그리기 코드 (lines 152-158) 제거
- `_draw_world()` 함수에서 노드 그리기 코드 (lines 160-187) 제거
- 용사 그리기 (lines 189-191)와 handler draw_world (lines 193-201)은 유지

**변경 후 `_draw_world()`**:
```lua
function GameScene:_draw_world()
  local floor = self.map:get_current_floor()
  if not floor then return end

  -- 용사 그리기 (금색)
  love.graphics.setColor(1, 0.8, 0)
  love.graphics.circle('fill', self.hero_world_x, self.hero_world_y, 20)

  -- 전투 관련 페이즈: 핸들러 월드 요소 그리기
  if self.phase == ENTERING_COMBAT or self.phase == COMBAT or self.phase == EXITING_COMBAT then
    self.combat_handler:draw_world()
  end

  -- 이벤트 관련 페이즈: 핸들러 월드 요소 그리기
  if self.phase == ENTERING_EVENT or self.phase == EVENT or self.phase == EXITING_EVENT then
    self.event_handler:draw_world()
  end
end
```

---

### Step 2: Minimap UI 위젯 생성

**파일**: `src/ui/minimap.lua` (신규)

**설계**:
- `UIElement` 상속
- 우측 상단 고정 배치 (화면 좌표, 카메라 영향 없음)
- 크기: 약 200x100 정도의 작은 박스
- 현재 floor의 Node-Edge 그래프를 축소하여 그림
  - 노드의 월드 좌표를 미니맵 좌표로 스케일 변환
  - 노드 타입별 색상 (전투=파랑, 이벤트=초록, 보스=빨강)
  - 완료 노드는 반투명
  - 현재 노드는 강조 (흰색 외곽선 또는 깜빡임)
  - 엣지는 얇은 선으로 표시
- 반투명 배경 패널
- 클릭 시 콜백 호출 (MapOverlay 열기용)

**주요 메서드**:
```lua
Minimap:initialize(x, y, width, height)
Minimap:set_map_data(floor, current_node)  -- 맵 데이터 바인딩
Minimap:set_on_click(callback)             -- 클릭 콜백
Minimap:update(dt)                         -- 깜빡임 애니메이션
Minimap:draw()                             -- 축소 맵 렌더링
Minimap:mousepressed(mx, my, button)       -- 클릭 감지
```

**좌표 변환 로직**:
```lua
-- 노드의 월드 좌표 → 미니맵 내 좌표
local function world_to_minimap(world_x, world_y, map_bounds, minimap_rect)
  local scale_x = minimap_rect.width / map_bounds.width
  local scale_y = minimap_rect.height / map_bounds.height
  local scale = math.min(scale_x, scale_y) * 0.9  -- 여백
  local mx = minimap_rect.x + (world_x - map_bounds.min_x) * scale + padding
  local my = minimap_rect.y + (world_y - map_bounds.min_y) * scale + padding
  return mx, my
end
```

---

### Step 3: MapOverlay 구현

**파일**: `src/ui/map_overlay.lua` (신규)

**설계 선택**: Handler 패턴 사용 (Scene이 아닌 GameScene 내부 모듈)

아키텍처 문서에는 MapOverlay를 별도 Scene으로 계획했지만, 현재 GameScene의 Handler 패턴과 일관성을 유지하기 위해 **GameScene 내부에서 관리하는 오버레이 UI 모듈**로 구현. SceneManager push/pop을 사용하지 않고, GameScene 자체에서 오버레이 상태를 관리.

**이유**:
- 현재 GameScene이 CombatHandler, EventHandler 등을 내부에서 관리하는 패턴 사용 중
- SceneManager push를 사용하면 GameScene의 update가 중단되어 tween 등이 멈출 수 있음
- 오버레이는 단순히 맵을 보여주는 UI이므로 별도 Scene보다 UI 모듈이 적합

**주요 기능**:
- 화면 전체를 덮는 반투명 어둠 배경 (alpha 0.85)
- 중앙에 전체 Node-Edge 그래프를 fit-to-screen으로 렌더링
- 노드 타입별 색상, 완료 상태, 현재 위치 표시
- 엣지를 선으로 표시
- 닫기 버튼 (우측 상단) 또는 ESC/M 키로 닫기
- 열기/닫기 시 fade 애니메이션 (flux tween)

**주요 메서드**:
```lua
MapOverlay:initialize()
MapOverlay:open(floor, current_node)   -- 오버레이 열기 + fade in
MapOverlay:close()                      -- 오버레이 닫기 + fade out
MapOverlay:is_open()                    -- 열림 상태 확인
MapOverlay:update(dt)
MapOverlay:draw()
MapOverlay:keypressed(key)              -- ESC/M으로 닫기
MapOverlay:mousepressed(mx, my, button) -- 닫기 버튼 클릭
```

---

### Step 4: GameScene에 Minimap & MapOverlay 통합

**파일**: `src/scene/game_scene.lua` (수정)

**변경 내용**:

1. **import 추가**: Minimap, MapOverlay require
2. **initialize()에서**:
   - `minimap_button` 제거 → `Minimap` 위젯으로 교체
   - `MapOverlay` 인스턴스 생성
   - Minimap 클릭 콜백에서 MapOverlay:open() 호출
3. **update()에서**:
   - `minimap_button:update(dt)` → `minimap:update(dt)` 교체
   - MapOverlay가 열려있으면 MapOverlay:update(dt) 호출
4. **draw()에서**:
   - `_draw_ui()` 내에서 `minimap_button:draw()` → `minimap:draw()` 교체
   - MapOverlay가 열려있으면 _draw_ui() 이후에 MapOverlay:draw() 호출
5. **keypressed()에서**:
   - 'M' 키로 MapOverlay 토글
   - MapOverlay가 열려있으면 ESC로 MapOverlay 닫기 (앱 종료 대신)
6. **mousepressed()에서**:
   - MapOverlay가 열려있으면 MapOverlay에만 이벤트 전달 (다른 UI 차단)
   - 닫혀있으면 기존 로직 + minimap:mousepressed() 호출
7. **노드 이동/페이즈 변경 시**: `minimap:set_map_data()` 업데이트

---

### Step 5: 문서 업데이트

**파일들**:

1. **`.omc/plans/game-core-architecture.md`**:
   - Phase 5 (Map Visualization) 섹션을 현재 구현에 맞게 업데이트
   - MapOverlay를 Scene이 아닌 UI 모듈로 변경된 점 반영
   - GameScene 클래스 설명에 Minimap, MapOverlay 필드 추가
   - 렌더링 파이프라인 설명 업데이트 (Node-Edge가 GameScene world에서 제거됨)

2. **`CLASS_DIAGRAM.md`**:
   - Concrete Scenes에서 MapOverlay 제거
   - UI System에 Minimap 위젯 상태 반영 (구현 완료로 표시)
   - GameScene 내부 구조에 MapOverlay 모듈 추가

---

## 파일 변경 요약

| 파일 | 작업 | 설명 |
|------|------|------|
| `src/scene/game_scene.lua` | 수정 | Node-Edge 렌더링 제거, Minimap/MapOverlay 통합 |
| `src/ui/minimap.lua` | 신규 | 축소 맵 그래프 UI 위젯 |
| `src/ui/map_overlay.lua` | 신규 | 전체 맵 오버레이 UI 모듈 |
| `.omc/plans/game-core-architecture.md` | 수정 | 아키텍처 변경 반영 |
| `CLASS_DIAGRAM.md` | 수정 | 클래스 다이어그램 업데이트 |

## 커밋 계획

1. `refactor(scene): GameScene에서 Node-Edge 그래프 직접 렌더링 제거`
2. `feat(ui): Minimap 축소 맵 위젯 구현`
3. `feat(ui): MapOverlay 전체 맵 오버레이 구현`
4. `feat(scene): GameScene에 Minimap/MapOverlay 통합`
5. `docs: 맵 시각화 아키텍처 변경사항 문서 업데이트`
