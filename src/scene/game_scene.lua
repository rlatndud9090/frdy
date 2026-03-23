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
local Spell = require('src.spell.spell')
local SpellBook = require('src.spell.spell_book')
local ManaManager = require('src.spell.mana_manager')
local SuspicionManager = require('src.spell.suspicion_manager')
local EventManager = require('src.event.event_manager')
local RewardManager = require('src.reward.reward_manager')
local RewardHandler = require('src.handler.reward_handler')
local RewardCatalog = require('src.reward.reward_catalog')
local RunContext = require('src.core.run_context')
local RunSave = require('src.core.run_save')
local RunSaveCoordinator = require('src.core.run_save_coordinator')
local GameSceneSaveParticipants = require('src.core.game_scene_save_participants')
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
local SETTLEMENT = "SETTLEMENT"
local EDGE_SELECT = "EDGE_SELECT"
local START_NODE_SELECT = "START_NODE_SELECT"

---@class GameScene : Scene
---@field phase string
---@field run_seed number
---@field run_context RunContext
---@field enemy_rng RNG
---@field map Map
---@field current_node Node|nil
---@field target_node Node|nil
---@field hero_world_x number
---@field hero_world_y number
---@field camera Camera
---@field hero Hero
---@field spell_book SpellBook
---@field mana_manager ManaManager
---@field suspicion_manager SuspicionManager
---@field event_manager EventManager
---@field floor_enemies table
---@field reward_manager RewardManager
---@field combat_handler CombatHandler
---@field event_handler EventHandler
---@field reward_handler RewardHandler
---@field edge_select_handler EdgeSelectHandler|nil
---@field overlay_alpha number
---@field suspicion_gauge Gauge
---@field mana_gauge Gauge
---@field minimap Minimap
---@field map_overlay MapOverlay
---@field settings_overlay SettingsOverlay
---@field restoring boolean
---@field save_coordinator RunSaveCoordinator
---@field save_feedback_text string|nil
---@field save_feedback_timer number
local GameScene = class('GameScene', Scene)

---@return number
function GameScene:_resolve_run_seed()
  local env_seed = os.getenv('FRDY_RUN_SEED')
  if env_seed and env_seed ~= '' then
    local parsed = tonumber(env_seed)
    if parsed then
      return RunContext.normalize_seed(parsed)
    end
  end
  return RunContext.normalize_seed(os.time())
end

---@return SpellBook
function GameScene:_build_initial_spell_book()
  local starter_spell_ids = require('data.spells.starter_spell_ids')
  local spells = {}
  for _, spell_id in ipairs(starter_spell_ids) do
    local spell_data = RewardCatalog.get_spell_data(spell_id)
    if spell_data then
      spells[#spells + 1] = Spell:new(spell_data)
    end
  end
  return SpellBook:new(spells)
end

---@return nil
function GameScene:_reset_world_position_for_current_floor()
  local floor = self.map:get_current_floor()
  local start_nodes = floor and floor:get_start_nodes() or {}
  self.current_node = nil
  self.target_node = nil
  self.hero_world_x = start_nodes[1] and start_nodes[1]:get_position().x or 0
  self.hero_world_y = 360
  self.camera:set_target(self.hero_world_x, self.hero_world_y)
  self.camera.x = self.hero_world_x
  self.camera.y = self.hero_world_y
  self.camera.target_x = self.hero_world_x
  self.camera.target_y = self.hero_world_y
  self.map:set_current_node(nil)
  self.minimap:set_map_data(floor, nil)
end

---@param run_seed? number
---@return nil
function GameScene:_initialize_runtime(run_seed)
  self.run_seed = run_seed or self:_resolve_run_seed()
  self.run_context = RunContext:new(self.run_seed)
  local map_rng = self.run_context:get_stream('gameplay.map')
  self.enemy_rng = self.run_context:get_stream('gameplay.enemy')

  local generator = MapGenerator:new(map_rng)
  local config = require('data.map_configs.default_config')
  self.map = generator:generate_map(config)

  self.camera = Camera:new(self.run_context:get_stream('ui.camera'))

  self.hero = Hero:new({hp = 50, attack = 8, defense = 2, speed = 8})
  self.spell_book = self:_build_initial_spell_book()

  local event_bus = Game:getInstance().event_bus
  self.mana_manager = ManaManager:new(100)
  self.suspicion_manager = SuspicionManager:new(event_bus)
  self.reward_manager = RewardManager:new(
    self.hero,
    self.spell_book,
    self.mana_manager,
    self.suspicion_manager,
    self.run_context:get_stream('gameplay.reward')
  )

  self.event_manager = EventManager:new(self.run_context:get_stream('gameplay.event'))
  self.event_manager:load_events(require('data.events.floor1_events'))
  self.floor_enemies = require('data.enemies.floor1_enemies')

  self.suspicion_gauge = Gauge:new(20, 20, 200, 30, "gauge.suspicion", {1, 0, 0})
  self.suspicion_gauge:set_value(0, 100)

  self.mana_gauge = Gauge:new(20, 60, 200, 30, "gauge.mana", {0, 0.5, 1})
  self.mana_gauge:set_value(self.mana_manager:get_current(), self.mana_manager:get_max())

  self.minimap = Minimap:new(1280 - 196, 16, 180, 100)
  self.minimap:set_on_click(function()
    self:_toggle_map_overlay()
  end)

  self.map_overlay = MapOverlay:new()
  self.settings_overlay = SettingsOverlay:new()
  self.settings_overlay:set_actions({
    {
      label_key = 'ui.continue_game',
      callback = function()
        self.settings_overlay:close()
      end,
    },
    {
      label_key = 'ui.abandon_run',
      callback = function()
        self:_abandon_run()
      end,
    },
  })

  self.combat_handler = CombatHandler:new()
  self.combat_handler:set_camera(self.camera)
  self.combat_handler:set_on_combat_end(function(result)
    self:_on_combat_ended(result)
  end)

  self.event_handler = EventHandler:new(self.run_context:get_stream('gameplay.event_choice'))
  self.event_handler:set_on_event_end(function()
    self:_on_event_ended()
  end)
  self.reward_handler = RewardHandler:new(self.run_context:get_stream('gameplay.reward_choice'))

  self.edge_select_handler = nil
  self.overlay_alpha = 0
  self.phase = START_NODE_SELECT
  self.save_feedback_text = nil
  self.save_feedback_timer = 0
  self:_reset_world_position_for_current_floor()
  self:_initialize_save_coordinator()
end

---@return nil
function GameScene:_initialize_save_coordinator()
  local registry = GameSceneSaveParticipants.build_registry({
    get_rng_snapshot = function()
      return self:get_rng_snapshot()
    end,
    restore_rng_snapshot = function(snapshot)
      return self:restore_rng_snapshot(snapshot)
    end,
    snapshot_map_progress = function()
      return self:_snapshot_map_progress()
    end,
    restore_map_progress = function(snapshot)
      self:_restore_map_progress(snapshot)
    end,
    hero = self.hero,
    spell_book = self.spell_book,
    mana_manager = self.mana_manager,
    suspicion_manager = self.suspicion_manager,
    reward_manager = self.reward_manager,
  })

  self.save_coordinator = RunSaveCoordinator:new({
    registry = registry,
    get_run_seed = function()
      return self.run_seed
    end,
    expected_system_keys = GameSceneSaveParticipants.expected_keys(),
  })
end

---@param message string|nil
---@return nil
function GameScene:_set_save_feedback(message)
  self.save_feedback_text = message
  self.save_feedback_timer = message and 4 or 0
end

---@param options? {save_data?: table, run_seed?: number}
function GameScene:initialize(options)
  Scene.initialize(self)
  options = options or {}
  self.restoring = false

  local save_data = options.save_data
  local initial_seed = options.run_seed
  if save_data then
    initial_seed = save_data.run_seed or initial_seed
  end

  self:_initialize_runtime(initial_seed)

  if save_data then
    local restored, restore_err = self:_restore_from_save(save_data)
    if not restored then
      error(restore_err or '세이브를 복원하지 못했습니다.')
    end
    return
  end

  local floor = self.map:get_current_floor()
  local start_nodes = floor and floor:get_start_nodes() or {}
  self:_write_checkpoint('start_node_select')
  self:_show_start_node_select(start_nodes)
end

---@return number
function GameScene:get_run_seed()
  return self.run_seed
end

---@return RunContextSnapshot
function GameScene:get_rng_snapshot()
  return self.run_context:snapshot()
end

---@param snapshot RunContextSnapshot
---@return boolean
function GameScene:restore_rng_snapshot(snapshot)
  return self.run_context:restore(snapshot)
end

---@return table
function GameScene:_snapshot_map_progress()
  local completed_node_ids = {}
  for floor_index = 1, self.map:get_total_floors() do
    local floor = self.map:get_floor(floor_index)
    for _, node in ipairs(floor:get_nodes()) do
      if node:is_completed() then
        completed_node_ids[#completed_node_ids + 1] = node.id
      end
    end
  end
  table.sort(completed_node_ids)
  return {
    current_floor_index = self.map.current_floor_index,
    current_node_id = self.current_node and self.current_node.id or nil,
    completed_node_ids = completed_node_ids,
  }
end

---@param node_id number|nil
---@return Node|nil
function GameScene:_find_node_by_id(node_id)
  if node_id == nil then
    return nil
  end

  for floor_index = 1, self.map:get_total_floors() do
    local floor = self.map:get_floor(floor_index)
    for _, node in ipairs(floor:get_nodes()) do
      if node.id == node_id then
        return node
      end
    end
  end

  return nil
end

---@param snapshot table|nil
---@return nil
function GameScene:_restore_map_progress(snapshot)
  if type(snapshot) ~= 'table' then
    return
  end

  self.map.current_floor_index = snapshot.current_floor_index or self.map.current_floor_index
  local completed_lookup = {}
  for _, node_id in ipairs(snapshot.completed_node_ids or {}) do
    completed_lookup[node_id] = true
  end

  for floor_index = 1, self.map:get_total_floors() do
    local floor = self.map:get_floor(floor_index)
    for _, node in ipairs(floor:get_nodes()) do
      node.completed = completed_lookup[node.id] == true
    end
  end

  local current_node = self:_find_node_by_id(snapshot.current_node_id)
  if current_node then
    self:_set_current_node(current_node)
    return
  end

  self:_reset_world_position_for_current_floor()
end

---@param checkpoint_kind string
---@return boolean
function GameScene:_write_checkpoint(checkpoint_kind)
  if self.restoring then
    return true
  end

  local ok, err = self.save_coordinator:save_checkpoint(checkpoint_kind)
  if not ok then
    self:_set_save_feedback(i18n.t('ui.save_write_failed'))
    print(err)
    return false
  end

  self:_set_save_feedback(nil)
  return ok
end

---@param checkpoint_kind string
---@return nil
function GameScene:_resume_from_checkpoint(checkpoint_kind)
  local floor = self.map:get_current_floor()
  if checkpoint_kind == 'combat_start' then
    self:_enter_combat()
    return
  end
  if checkpoint_kind == 'event_start' then
    self:_enter_event()
    return
  end
  if checkpoint_kind == 'reward_offer_presented' then
    self.phase = SETTLEMENT
    self:_show_next_reward_offer()
    return
  end
  if checkpoint_kind == 'path_ready' then
    self:_check_next_move()
    return
  end

  self:_show_start_node_select(floor and floor:get_start_nodes() or {})
end

---@param save_data table
---@return boolean
---@return string|nil
function GameScene:_restore_from_save(save_data)
  self.restoring = true

  local normalized_save_data, restore_err = self.save_coordinator:restore_payload(save_data)
  if not normalized_save_data then
    self.restoring = false
    return false, restore_err
  end

  local checkpoint_kind = normalized_save_data.checkpoint and normalized_save_data.checkpoint.kind or 'start_node_select'
  self:_resume_from_checkpoint(checkpoint_kind)
  self.restoring = false
  return true, nil
end

---@param dt number
function GameScene:update(dt)
  self.camera:update(dt)

  if self.save_feedback_timer > 0 then
    self.save_feedback_timer = math.max(0, self.save_feedback_timer - dt)
    if self.save_feedback_timer <= 0 then
      self.save_feedback_text = nil
    end
  end

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
  elseif self.phase == SETTLEMENT then
    self.reward_handler:update(dt)
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

  -- 전투 중이 아닐 때만 좌측 게이지 표시 (전투 중에는 SpellBookOverlay가 표시)
  if self.phase ~= COMBAT and self.phase ~= ENTERING_COMBAT and self.phase ~= EXITING_COMBAT then
    self.suspicion_gauge:draw()
    self.mana_gauge:draw()

    -- 용사 HP (텍스트)
    love.graphics.setColor(0.2, 0.8, 0.2, 1)
    love.graphics.print(i18n.t("gauge.hero_hp", {current = self.hero:get_hp(), max = self.hero:get_max_hp()}), 20, 100)
    love.graphics.setColor(0.82, 0.82, 0.95, 1)
    love.graphics.print(i18n.t("progress.hero_level", {level = self.hero:get_level()}), 20, 122)
    love.graphics.print(
      i18n.t("progress.hero_xp", {current = self.hero:get_experience(), max = self.hero:get_next_level_experience()}),
      20,
      144
    )
    local awakening = self.reward_manager:get_demon_awakening()
    love.graphics.print(
      i18n.t("progress.demon_awaken", {current = awakening:get_progress(), max = awakening:get_threshold()}),
      20,
      166
    )
    love.graphics.setColor(1, 1, 1)
  end

  -- 미니맵은 항상 표시 (우측 상단이므로 충돌 없음)
  self.minimap:draw()

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

  if self.phase == SETTLEMENT then
    self.reward_handler:draw()
  end

  -- 디버그: 현재 페이즈 표시
  love.graphics.setColor(1, 1, 1)
  love.graphics.print("Phase: " .. self.phase, 10, 700)

  if self.save_feedback_text then
    love.graphics.setColor(0.95, 0.62, 0.48, 1)
    love.graphics.printf(self.save_feedback_text, 0, 672, love.graphics.getWidth(), 'center')
  end
end

---@param key string
---@return boolean
function GameScene:_is_settings_input_locked()
  return self.settings_overlay:is_open()
end

---@param key string
function GameScene:keypressed(key)
  if self:_is_settings_input_locked() then
    self.settings_overlay:keypressed(key)
    return
  end

  if self.map_overlay:is_open() then
    self.map_overlay:keypressed(key)
    return
  end

  if self.phase == COMBAT and self.combat_handler:keypressed(key) then
    return
  end

  if self.phase == COMBAT and self.combat_handler:is_input_locked() then
    return
  end

  if self.phase == SETTLEMENT then
    return
  end

  if key == "escape" or key == "tab" then
    self.settings_overlay:open()
    return
  end

  if key == "m" then
    self:_toggle_map_overlay()
  end
end

---@param x number
---@param y number
---@param button number
function GameScene:mousepressed(x, y, button)
  if self:_is_settings_input_locked() then
    self.settings_overlay:mousepressed(x, y, button)
    return
  end

  if self.map_overlay:is_open() then
    self.map_overlay:mousepressed(x, y, button)
    return
  end

  if self.phase == COMBAT and self.combat_handler:is_input_locked() then
    self.combat_handler:mousepressed(x, y, button)
    return
  end

  if self.phase == SETTLEMENT then
    self.reward_handler:mousepressed(x, y, button)
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

---@return table
function GameScene:_build_run_end_summary()
  return {
    floor = self.map and self.map.current_floor_index or 1,
    level = self.hero and self.hero:get_level() or 1,
  }
end

---@param reason string
---@return nil
function GameScene:_finish_run(reason)
  RunSave:clear()
  local RunEndScene = require('src.scene.run_end_scene')
  Game:getInstance():switch_scene(RunEndScene:new({
    reason = reason,
    summary = self:_build_run_end_summary(),
  }))
end

---@return nil
function GameScene:_abandon_run()
  self.settings_overlay:close()
  self:_finish_run('abandon')
end

function GameScene:_check_next_move()
  if not self.current_node then
    return
  end

  local edges = self:_get_outgoing_edges()

  if #edges == 0 then
    print(i18n.t("combat.floor_cleared"))
    self:_finish_run('victory')
    return
  elseif #edges == 1 then
    self:_start_traveling(edges[1]:get_to_node())
  else
    self:_show_edge_select(edges)
  end
end

---@return Edge[]
function GameScene:_get_outgoing_edges()
  if not self.current_node then
    return {}
  end

  local floor = self.map and self.map:get_current_floor() or nil
  if not floor or not floor.get_edges_from then
    return {}
  end

  return floor:get_edges_from(self.current_node) or {}
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
  local arrived_node = self.target_node
  self.target_node = nil
  if not arrived_node then
    return
  end

  self:_set_current_node(arrived_node)
  self:_enter_current_node()
end

---@param node Node
---@return nil
function GameScene:_set_current_node(node)
  self.current_node = node
  self.map:set_current_node(self.current_node)
  self.current_node:mark_completed()

  local pos = self.current_node:get_position()
  self.hero_world_x = pos.x
  self.hero_world_y = pos.y
  self.camera.x = self.hero_world_x
  self.camera.y = self.hero_world_y
  self.camera.target_x = self.hero_world_x
  self.camera.target_y = self.hero_world_y

  self.minimap:set_map_data(self.map:get_current_floor(), self.current_node)
end

---@return nil
function GameScene:_enter_current_node()
  if not self.current_node then
    return
  end

  local node_type = self.current_node:get_type()
  if node_type == "combat" then
    self:_write_checkpoint('combat_start')
    self:_enter_combat()
  elseif node_type == "event" then
    self:_write_checkpoint('event_start')
    self:_enter_event()
  else
    self:_check_next_move()
  end
end
function GameScene:_enter_combat()
  self.phase = ENTERING_COMBAT

  -- 적 생성
  local enemies = self:_create_enemies()

  -- combat_handler에 전투 데이터 전달
  self.combat_handler:start_combat(
    self.hero,
    enemies,
    self.spell_book,
    self.mana_manager,
    self.suspicion_manager,
    self.reward_manager
  )
  self.combat_handler.hero_world_x = self.hero_world_x
  self.combat_handler.hero_world_y = self.hero_world_y

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
    local count = self.enemy_rng:next_int(1, 2)
    for _ = 1, count do
      local key = enemy_keys[self.enemy_rng:next_int(1, #enemy_keys)]
      local data = self.floor_enemies[key]
      table.insert(enemies, Enemy:new(data.name, data.stats, data.action_patterns))
    end

    if node.is_elite and node:is_elite() then
      local elite_enemies = {}
      local elite_count = self.enemy_rng:next_int(2, 3)
      for _ = 1, elite_count do
        local key = enemy_keys[self.enemy_rng:next_int(1, #enemy_keys)]
        local data = self.floor_enemies[key]
        local stats = {
          hp = math.max(1, math.floor((data.stats.hp or 1) * 1.4 + 0.5)),
          attack = math.max(1, math.floor((data.stats.attack or 1) * 1.25 + 0.5)),
          defense = math.max(0, math.floor((data.stats.defense or 0) * 1.2 + 0.5)),
          speed = math.max(1, math.floor((data.stats.speed or 1) * 1.1 + 0.5)),
        }
        table.insert(elite_enemies, Enemy:new(data.name, stats, data.action_patterns))
      end
      return elite_enemies
    end
  end

  return enemies
end

--- 전투 종료 처리
---@param result string
function GameScene:_on_combat_ended(result)
  self.phase = EXITING_COMBAT
  self.combat_handler:deactivate()

  -- 전투 후 마나 회복
  self.mana_manager:recover_after_combat(30)

  if result == "victory" then
    self.reward_manager:prepare_combat_settlement(result, self.current_node)
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
        self:_finish_run('death')
        return
      end
      self:_enter_settlement_or_continue()
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
    reward_manager = self.reward_manager,
    spell_book = self.spell_book,
    mana_manager = self.mana_manager,
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
      self:_enter_settlement_or_continue()
    end)
end

---@return nil
function GameScene:_enter_settlement_or_continue()
  if self.reward_manager:has_pending_offers() then
    self.phase = SETTLEMENT
    self:_show_next_reward_offer()
    return
  end
  self.phase = ARRIVING
  self:_continue_after_settlement()
end

---@return nil
function GameScene:_continue_after_settlement()
  if #self:_get_outgoing_edges() == 0 then
    self:_finish_run('victory')
    return
  end

  self:_write_checkpoint('path_ready')
  self:_check_next_move()
end

---@return nil
function GameScene:_show_next_reward_offer()
  local offer = self.reward_manager:peek_offer()
  if not offer then
    self.phase = ARRIVING
    self:_continue_after_settlement()
    return
  end

  self:_write_checkpoint('reward_offer_presented')
  self.reward_handler:start_offer(offer, {
    hero = self.hero,
  }, function(selected_option)
    self.reward_manager:resolve_current_offer(selected_option)
    self:_show_next_reward_offer()
  end)
end

---@param start_nodes Node[]
function GameScene:_show_start_node_select(start_nodes)
  self.phase = START_NODE_SELECT
  self.map_overlay:open(self.map:get_current_floor(), nil, {
    start_select_mode = true,
    start_nodes = start_nodes,
    on_start_node_selected = function(node)
      self:_on_start_node_selected(node)
    end,
  })
end

---@param node Node
function GameScene:_on_start_node_selected(node)
  self.phase = ARRIVING
  self.target_node = nil
  self:_set_current_node(node)
  self:_enter_current_node()
end
---@param edges Edge[]
function GameScene:_show_edge_select(edges)
  self.phase = EDGE_SELECT

  if not self.edge_select_handler then
    self.edge_select_handler = EdgeSelectHandler:new(edges, function(edge)
      self:_on_edge_selected(edge)
    end, {
      hero = self.hero,
    }, self.run_context:get_stream('gameplay.path_choice'))
  else
    self.edge_select_handler:setup(edges, function(edge)
      self:_on_edge_selected(edge)
    end, {
      hero = self.hero,
    })
  end

  self.edge_select_handler:activate()
end

--- 경로 선택 완료 처리
---@param edge Edge
function GameScene:_on_edge_selected(edge)
  self:_start_traveling(edge:get_to_node())
end

---@param x number
---@param y number
function GameScene:wheelmoved(x, y)
  if self:_is_settings_input_locked() then
    return
  end

  if self.map_overlay:is_open() then
    self.map_overlay:wheelmoved(x, y)
    return
  end

  if self.phase == COMBAT then
    self.combat_handler:wheelmoved(x, y)
  end
end
function GameScene:_toggle_map_overlay()
  if self.map_overlay:is_open() then
    self.map_overlay:close()
  else
    self.map_overlay:open(self.map:get_current_floor(), self.current_node)
  end
end

return GameScene
