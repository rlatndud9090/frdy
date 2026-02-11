local class = require('lib.middleclass')
local flux = require('lib.flux')
local Scene = require('src.core.scene')
local Camera = require('src.anim.camera')
local MapGenerator = require('src.map.map_generator')
local Gauge = require('src.ui.gauge')
local Minimap = require('src.ui.minimap')
local MapOverlay = require('src.ui.map_overlay')
local SettingsOverlay = require('src.ui.settings_overlay')
local CombatHandler = require('src.handler.combat_handler')
local EventHandler = require('src.handler.event_handler')
local EdgeSelectHandler = require('src.handler.edge_select_handler')
local Hero = require('src.combat.hero')
local Enemy = require('src.combat.enemy')
local Card = require('src.card.card')
local Deck = require('src.card.deck')
local ManaManager = require('src.card.mana_manager')
local SuspicionManager = require('src.card.suspicion_manager')
local EventManager = require('src.event.event_manager')
local Game = require('src.core.game')
local i18n = require('src.i18n.init')

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
---@field hero Hero
---@field deck Deck
---@field mana_manager ManaManager
---@field suspicion_manager SuspicionManager
---@field event_manager EventManager
---@field floor_enemies table
---@field combat_handler CombatHandler
---@field event_handler EventHandler
---@field edge_select_handler EdgeSelectHandler|nil
---@field overlay_alpha number
---@field suspicion_gauge Gauge
---@field mana_gauge Gauge
---@field minimap Minimap
---@field map_overlay MapOverlay
---@field settings_overlay SettingsOverlay
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

  -- 게임 객체 생성
  self.hero = Hero:new({hp = 50, attack = 8, defense = 2})

  -- 카드 덱 생성
  local base_cards_data = require('data.cards.base_cards')
  local cards = {}
  for _, card_data in ipairs(base_cards_data) do
    table.insert(cards, Card:new(card_data))
  end
  self.deck = Deck:new(cards)

  -- 매니저 생성
  local event_bus = Game:getInstance().event_bus
  self.mana_manager = ManaManager:new(3)
  self.suspicion_manager = SuspicionManager:new(event_bus)

  -- 이벤트 매니저 생성
  self.event_manager = EventManager:new()
  self.event_manager:load_events(require('data.events.floor1_events'))

  -- 적 데이터 로드
  self.floor_enemies = require('data.enemies.floor1_enemies')

  -- UI 위젯 생성
  self.suspicion_gauge = Gauge:new(20, 20, 200, 30, "gauge.suspicion", {1, 0, 0})
  self.suspicion_gauge:set_value(0, 100)

  self.mana_gauge = Gauge:new(20, 60, 200, 30, "gauge.mana", {0, 0.5, 1})
  self.mana_gauge:set_value(self.mana_manager:get_current(), self.mana_manager:get_max())

  self.minimap = Minimap:new(1280 - 220, 16, 200, 100)
  self.minimap:set_map_data(floor, self.current_node)
  self.minimap:set_on_click(function()
    self:_toggle_map_overlay()
  end)

  self.map_overlay = MapOverlay:new()
  self.settings_overlay = SettingsOverlay:new()

  -- 핸들러 생성
  self.combat_handler = CombatHandler:new()
  self.combat_handler:set_on_combat_end(function(result)
    self:_on_combat_ended(result)
  end)

  self.event_handler = EventHandler:new()
  self.event_handler:set_on_event_end(function()
    self:_on_event_ended()
  end)

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
  self.minimap:update(dt)
  self.map_overlay:update(dt)
  self.settings_overlay:update(dt)

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

  -- 게이지 실시간 갱신
  self.suspicion_gauge:set_value(self.suspicion_manager:get_level(), self.suspicion_manager:get_max())
  self.mana_gauge:set_value(self.mana_manager:get_current(), self.mana_manager:get_max())
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

  -- 맵 오버레이 (UI 위에 그려야 함)
  self.map_overlay:draw()

  -- 설정 오버레이 (최상위)
  self.settings_overlay:draw()
end

--- 월드 요소 그리기 (용사 + 핸들러 월드 요소만. 맵 그래프는 Minimap/MapOverlay에서 표시)
function GameScene:_draw_world()
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

  -- 게이지 및 미니맵
  self.suspicion_gauge:draw()
  self.mana_gauge:draw()
  self.minimap:draw()

  -- 용사 HP (텍스트)
  love.graphics.setColor(0.2, 0.8, 0.2, 1)
  love.graphics.print(i18n.t("gauge.hero_hp", {current = self.hero:get_hp(), max = self.hero:get_max_hp()}), 20, 100)
  love.graphics.setColor(1, 1, 1)

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
  -- 설정 오버레이가 열려있으면 설정에 키 이벤트 우선 전달
  if self.settings_overlay:is_open() then
    self.settings_overlay:keypressed(key)
    return
  end

  -- 맵 오버레이가 열려있으면 오버레이에 키 이벤트 우선 전달
  if self.map_overlay:is_open() then
    self.map_overlay:keypressed(key)
    return
  end

  if key == "tab" then
    self.settings_overlay:open()
  elseif key == "escape" then
    love.event.quit()
  elseif key == "m" then
    self:_toggle_map_overlay()
  end
end

---@param x number
---@param y number
---@param button number
function GameScene:mousepressed(x, y, button)
  -- 설정 오버레이가 열려있으면 설정에만 이벤트 전달
  if self.settings_overlay:is_open() then
    self.settings_overlay:mousepressed(x, y, button)
    return
  end

  -- 맵 오버레이가 열려있으면 오버레이에만 이벤트 전달
  if self.map_overlay:is_open() then
    self.map_overlay:mousepressed(x, y, button)
    return
  end

  self.minimap:mousepressed(x, y, button)

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
    print(i18n.t("combat.floor_cleared"))
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

  -- 미니맵 데이터 갱신
  self.minimap:set_map_data(self.map:get_current_floor(), self.current_node)

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

  -- 적 생성
  local enemies = self:_create_enemies()

  -- combat_handler에 전투 데이터 전달
  self.combat_handler:start_combat(self.hero, enemies, self.deck, self.mana_manager, self.suspicion_manager)

  -- 애니메이션
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

--- 적 생성
---@return Enemy[]
function GameScene:_create_enemies()
  local enemies = {}
  local node = self.current_node

  if node:is_boss() then
    -- 보스 노드: 암흑기사
    local data = self.floor_enemies.boss_dark_knight
    table.insert(enemies, Enemy:new(data.name, data.stats, data.action_patterns))
  else
    -- 일반 전투: 랜덤 1~2마리
    local enemy_keys = {"slime", "goblin", "skeleton", "wolf"}
    local count = math.random(1, 2)
    for _ = 1, count do
      local key = enemy_keys[math.random(#enemy_keys)]
      local data = self.floor_enemies[key]
      table.insert(enemies, Enemy:new(data.name, data.stats, data.action_patterns))
    end
  end

  return enemies
end

--- 전투 종료 처리
---@param result string
function GameScene:_on_combat_ended(result)
  self.phase = EXITING_COMBAT
  self.combat_handler:deactivate()

  if result == "victory" then
    -- 용사 성장
    self.hero:grow({exp = 30, hp_bonus = 0, attack_bonus = 0})
  elseif result == "defeat" then
    -- 패배 처리 (TODO: 게임 오버 화면)
    print(i18n.t("combat.defeat"))
  end

  flux.to(self.combat_handler, 0.4, {enemy_world_x = self.hero_world_x + 800})
    :ease("quadin")
  flux.to(self.combat_handler, 0.3, {ui_offset_y = 200})
    :ease("quadin")
  flux.to(self, 0.3, {overlay_alpha = 0})
    :ease("linear")
    :oncomplete(function()
      if result == "defeat" then
        return  -- 게임 오버 시 진행하지 않음
      end
      self:_check_next_move()
    end)
end

--- 이벤트 진입 연출
function GameScene:_enter_event()
  self.phase = ENTERING_EVENT

  -- 이벤트 가져오기
  local event = self.event_manager:get_random_event()
  if not event then
    -- 이벤트가 없으면 바로 다음으로 진행
    self:_check_next_move()
    return
  end

  -- event_handler에 이벤트 데이터 전달
  self.event_handler:start_event(event, {
    hero = self.hero,
    suspicion_manager = self.suspicion_manager,
  })

  -- 애니메이션
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

--- 이벤트 종료 처리
function GameScene:_on_event_ended()
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

--- 맵 오버레이 토글
function GameScene:_toggle_map_overlay()
  if self.map_overlay:is_open() then
    self.map_overlay:close()
  else
    self.map_overlay:open(self.map:get_current_floor(), self.current_node)
  end
end

return GameScene
