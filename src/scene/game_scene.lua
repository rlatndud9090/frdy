local class = require('lib.middleclass')
local flux = require('lib.flux')
local Scene = require('src.core.scene')
local Camera = require('src.anim.camera')
local MapGenerator = require('src.map.map_generator')
local Gauge = require('src.ui.gauge')
local Button = require('src.ui.button')
local CombatHandler = require('src.handler.combat_handler')
local EventHandler = require('src.handler.event_handler')
local EdgeSelectHandler = require('src.handler.edge_select_handler')

local SEGMENT_WIDTH = 300

-- 페이즈 상수
local TRAVELING = "TRAVELING"
local ARRIVING = "ARRIVING"
local ENTERING_COMBAT = "ENTERING_COMBAT"
local COMBAT = "COMBAT"
local EXITING_COMBAT = "EXITING_COMBAT"
local ENTERING_EVENT = "ENTERING_EVENT"
local EVENT = "EVENT"
local EXITING_EVENT = "EXITING_EVENT"
local EDGE_SELECT = "EDGE_SELECT"

---@class GameScene : Scene
---@field phase string
---@field map Map
---@field current_node Node|nil
---@field target_node Node|nil
---@field hero_world_x number
---@field hero_world_y number
---@field camera Camera
---@field combat_handler CombatHandler
---@field event_handler EventHandler
---@field edge_select_handler EdgeSelectHandler|nil
---@field overlay_alpha number
---@field suspicion_gauge Gauge
---@field mana_gauge Gauge
---@field minimap_button Button
local GameScene = class('GameScene', Scene)

function GameScene:initialize()
  Scene.initialize(self)

  -- 맵 생성
  local generator = MapGenerator:new()
  local config = require('data.map_configs.default_config')
  self.map = generator:generate_map(config)

  -- 시작 노드에 배치
  local floor = self.map:get_current_floor()
  local start_nodes = floor:get_start_nodes()
  self.current_node = start_nodes[1]
  self.target_node = nil

  -- 용사 월드 좌표
  self.hero_world_x = self.current_node:get_position().x
  self.hero_world_y = 360

  -- 카메라 생성 및 즉시 위치 설정 (초기 lerp 없이)
  self.camera = Camera:new()
  self.camera:set_target(self.hero_world_x, self.hero_world_y)
  self.camera.x = self.hero_world_x
  self.camera.target_x = self.hero_world_x

  -- UI 위젯 생성
  self.suspicion_gauge = Gauge:new(20, 20, 200, 30, "의심", {1, 0, 0})
  self.suspicion_gauge:set_value(0)
  self.suspicion_gauge:set_max(100)

  self.mana_gauge = Gauge:new(20, 60, 200, 30, "마나", {0, 0.5, 1})
  self.mana_gauge:set_value(3, 3)

  self.minimap_button = Button:new(1280 - 120, 20, 100, 40, "미니맵")
  self.minimap_button:set_on_click(function()
    print("미니맵 버튼 클릭됨")
  end)

  -- 핸들러 생성
  self.combat_handler = CombatHandler:new({
    on_end_callback = function()
      self:_on_combat_ended()
    end
  })

  self.event_handler = EventHandler:new({
    on_choice_callback = function(index)
      self:_on_event_choice(index)
    end
  })

  self.edge_select_handler = nil

  -- 초기 상태
  self.phase = TRAVELING
  self.overlay_alpha = 0

  -- 시작 노드 완료 처리
  self.current_node:mark_completed()

  -- 게임 흐름 시작
  self:_check_next_move()
end

---@param dt number
function GameScene:update(dt)
  self.camera:update(dt)

  -- UI 위젯 업데이트
  self.suspicion_gauge:update(dt)
  self.mana_gauge:update(dt)
  self.minimap_button:update(dt)

  -- 페이즈별 업데이트
  if self.phase == TRAVELING then
    self.camera:set_target(self.hero_world_x, self.hero_world_y)
  elseif self.phase == COMBAT then
    self.combat_handler:update(dt)
  elseif self.phase == EVENT then
    self.event_handler:update(dt)
  elseif self.phase == EDGE_SELECT then
    if self.edge_select_handler then
      self.edge_select_handler:update(dt)
    end
  else
    -- ENTERING_*, EXITING_*, ARRIVING: flux 처리, 카메라 타겟만 갱신
    self.camera:set_target(self.hero_world_x, self.hero_world_y)
  end
end

function GameScene:draw()
  -- 월드 렌더링
  self.camera:apply()
  self:_draw_world()
  self.camera:release()

  -- 어둠 오버레이
  if self.overlay_alpha > 0 then
    love.graphics.setColor(0, 0, 0, self.overlay_alpha)
    love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
  end

  -- UI 렌더링
  self:_draw_ui()
end

--- 월드 요소 그리기
function GameScene:_draw_world()
  local floor = self.map:get_current_floor()
  if not floor then return end

  -- 엣지 그리기
  love.graphics.setColor(0.5, 0.5, 0.5, 0.3)
  for _, edge in ipairs(floor.edges) do
    local from_pos = edge:get_from_node():get_position()
    local to_pos = edge:get_to_node():get_position()
    love.graphics.line(from_pos.x, from_pos.y, to_pos.x, to_pos.y)
  end

  -- 노드 그리기
  for _, node in ipairs(floor:get_nodes()) do
    local pos = node:get_position()
    local node_type = node:get_type()
    local alpha = node:is_completed() and 0.4 or 1.0

    -- 노드 타입별 색상 및 크기
    local radius = 30
    if node_type == "combat" then
      -- 보스 노드 판별
      if node.is_boss and node:is_boss() then
        love.graphics.setColor(0.8, 0.1, 0.1, alpha)
        radius = 40
      else
        love.graphics.setColor(0.3, 0.3, 0.8, alpha)
      end
    elseif node_type == "event" then
      love.graphics.setColor(0.2, 0.7, 0.3, alpha)
    end

    love.graphics.circle('fill', pos.x, pos.y, radius)

    -- 현재 노드 흰색 외곽선
    if node == self.current_node then
      love.graphics.setColor(1, 1, 1, alpha)
      love.graphics.circle('line', pos.x, pos.y, radius)
    end
  end

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

--- UI 요소 그리기
function GameScene:_draw_ui()
  love.graphics.setColor(1, 1, 1)

  -- 게이지 및 버튼
  self.suspicion_gauge:draw()
  self.mana_gauge:draw()
  self.minimap_button:draw()

  -- 전투 관련 페이즈: 핸들러 UI 그리기
  if self.phase == ENTERING_COMBAT or self.phase == COMBAT or self.phase == EXITING_COMBAT then
    self.combat_handler:draw_ui()
  end

  -- 이벤트 관련 페이즈: 핸들러 UI 그리기
  if self.phase == ENTERING_EVENT or self.phase == EVENT or self.phase == EXITING_EVENT then
    self.event_handler:draw_ui()
  end

  -- 경로 선택 페이즈: 핸들러 그리기
  if self.phase == EDGE_SELECT then
    if self.edge_select_handler then
      self.edge_select_handler:draw()
    end
  end

  -- 디버그: 현재 페이즈 표시
  love.graphics.setColor(1, 1, 1)
  love.graphics.print("Phase: " .. self.phase, 10, 700)
end

---@param key string
function GameScene:keypressed(key)
  if key == "escape" then
    love.event.quit()
  elseif key == "m" then
    print("미니맵")
  end
end

---@param x number
---@param y number
---@param button number
function GameScene:mousepressed(x, y, button)
  self.minimap_button:mousepressed(x, y, button)

  if self.phase == COMBAT then
    self.combat_handler:mousepressed(x, y, button)
  elseif self.phase == EVENT then
    self.event_handler:mousepressed(x, y, button)
  elseif self.phase == EDGE_SELECT and self.edge_select_handler then
    self.edge_select_handler:mousepressed(x, y, button)
  end
end

--- 다음 이동 결정
function GameScene:_check_next_move()
  local floor = self.map:get_current_floor()
  local edges = floor:get_edges_from(self.current_node)

  if #edges == 0 then
    print("층 클리어!")
    return
  elseif #edges == 1 then
    self:_start_traveling(edges[1]:get_to_node())
  else
    self:_show_edge_select(edges)
  end
end

--- 이동 시작
---@param target_node Node
function GameScene:_start_traveling(target_node)
  self.target_node = target_node
  self.phase = TRAVELING

  local target_x = target_node:get_position().x
  local distance = math.abs(target_x - self.hero_world_x)
  local duration = math.max(0.5, math.min(2.0, distance / 300))

  flux.to(self, duration, {hero_world_x = target_x})
    :ease("quadinout")
    :oncomplete(function()
      self:_on_arrived()
    end)
end

--- 도착 처리
function GameScene:_on_arrived()
  self.phase = ARRIVING
  self.current_node = self.target_node
  self.target_node = nil
  self.map:set_current_node(self.current_node)
  self.current_node:mark_completed()

  local node_type = self.current_node:get_type()
  if node_type == "combat" then
    self:_enter_combat()
  elseif node_type == "event" then
    self:_enter_event()
  end
end

--- 전투 진입 연출
function GameScene:_enter_combat()
  self.phase = ENTERING_COMBAT

  self.combat_handler.enemy_world_x = self.hero_world_x + 800
  self.combat_handler.enemy_world_y = self.hero_world_y + 60
  self.combat_handler.ui_offset_y = 200

  flux.to(self.combat_handler, 0.6, {enemy_world_x = self.hero_world_x + 300})
    :ease("backout")
  flux.to(self.combat_handler, 0.5, {ui_offset_y = 0})
    :ease("quadout")
  flux.to(self, 0.6, {overlay_alpha = 0.3})
    :ease("linear")
    :oncomplete(function()
      self.phase = COMBAT
      self.combat_handler:activate()
    end)
end

--- 전투 종료 처리
function GameScene:_on_combat_ended()
  self.phase = EXITING_COMBAT
  self.combat_handler:deactivate()

  flux.to(self.combat_handler, 0.4, {enemy_world_x = self.hero_world_x + 800})
    :ease("quadin")
  flux.to(self.combat_handler, 0.3, {ui_offset_y = 200})
    :ease("quadin")
  flux.to(self, 0.3, {overlay_alpha = 0})
    :ease("linear")
    :oncomplete(function()
      self:_check_next_move()
    end)
end

--- 이벤트 진입 연출
function GameScene:_enter_event()
  self.phase = ENTERING_EVENT

  self.event_handler.npc_world_x = self.hero_world_x + 200
  self.event_handler.npc_world_y = self.hero_world_y
  self.event_handler.panel_alpha = 0
  self.event_handler.panel_y = -200

  flux.to(self.event_handler, 0.5, {panel_alpha = 1, panel_y = 0})
    :ease("quadout")
    :oncomplete(function()
      self.phase = EVENT
      self.event_handler:activate()
    end)
end

--- 이벤트 선택 처리
---@param choice_index number
function GameScene:_on_event_choice(choice_index)
  self.phase = EXITING_EVENT
  self.event_handler:deactivate()

  flux.to(self.event_handler, 0.3, {panel_alpha = 0, panel_y = -200})
    :ease("quadin")
    :oncomplete(function()
      self:_check_next_move()
    end)
end

--- 경로 선택 표시
---@param edges Edge[]
function GameScene:_show_edge_select(edges)
  self.phase = EDGE_SELECT

  if not self.edge_select_handler then
    self.edge_select_handler = EdgeSelectHandler:new(edges, function(edge)
      self:_on_edge_selected(edge)
    end)
  else
    self.edge_select_handler:setup(edges, function(edge)
      self:_on_edge_selected(edge)
    end)
  end

  self.edge_select_handler:activate()
end

--- 경로 선택 완료 처리
---@param edge Edge
function GameScene:_on_edge_selected(edge)
  self:_start_traveling(edge:get_to_node())
end

return GameScene
