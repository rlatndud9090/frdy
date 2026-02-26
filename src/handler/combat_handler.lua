local class = require('lib.middleclass')
local CombatManager = require('src.combat.combat_manager')
local PredictedAction = require('src.combat.predicted_action')
local Gauge = require('src.ui.gauge')
local SpellBookOverlay = require('src.ui.spell_book_overlay')
local TimelineUI = require('src.ui.timeline_ui')
local i18n = require('src.i18n.init')

---@class CombatHandler
---@field combat_manager CombatManager
---@field camera Camera|nil
---@field spell_book SpellBook|nil
---@field mana_manager ManaManager|nil
---@field suspicion_manager SuspicionManager|nil
---@field hero_gauge Gauge
---@field enemy_gauges Gauge[]
---@field spell_book_overlay SpellBookOverlay
---@field timeline_ui TimelineUI
---@field on_combat_end function|nil
---@field enemy_world_x number
---@field enemy_world_y number
---@field ui_offset_y number
---@field active boolean
---@field execution_timer number
---@field execution_delay number
---@field combat_log string[]
---@field log_timer number
---@field insert_selection_phase string "IDLE"|"SELECT_TARGET"|"SELECT_TIMING"
---@field pending_insert_spell Spell|nil
---@field pending_insert_target Entity|nil
---@field hovered_insert_target Enemy|nil
local CombatHandler = class('CombatHandler')

function CombatHandler:initialize()
  self.combat_manager = CombatManager:new()
  self.camera = nil
  self.spell_book = nil
  self.mana_manager = nil
  self.suspicion_manager = nil

  -- UI
  self.hero_gauge = Gauge:new(50, 520, 200, 25, "entity.hero", {0.2, 0.8, 0.2})
  self.enemy_gauges = {}

  -- SpellBook Overlay (replaces SpellPanel + confirm/reset buttons)
  self.spell_book_overlay = SpellBookOverlay:new()
  self.spell_book_overlay:set_visible(false)
  self.spell_book_overlay:set_on_play(function(spell)
    self:_on_spell_selected(spell)
  end)
  self.spell_book_overlay:set_on_confirm(function()
    self:_confirm_planning()
  end)
  self.spell_book_overlay:set_on_reset(function()
    self:_reset_planning()
  end)

  -- Timeline UI
  self.timeline_ui = TimelineUI:new()
  self.timeline_ui:set_visible(false)
  self.timeline_ui:set_on_insert(function(spell, insert_index)
    self:_insert_spell_at(spell, insert_index)
  end)
  self.timeline_ui:set_on_manipulate(function(spell, target_index, dest_index)
    self:_on_manipulate_applied(spell, target_index, dest_index)
  end)
  self.timeline_ui:set_on_global(function(spell)
    self:_on_global_applied(spell)
  end)

  self.on_combat_end = nil

  -- Animation fields
  self.enemy_world_x = 1280 + 200
  self.enemy_world_y = 300
  self.ui_offset_y = 200

  self.active = false
  self.execution_timer = 0
  self.execution_delay = 0.5

  self.combat_log = {}
  self.log_timer = 0
  self.insert_selection_phase = "IDLE"
  self.pending_insert_spell = nil
  self.pending_insert_target = nil
  self.hovered_insert_target = nil
end

function CombatHandler:set_on_combat_end(callback)
  self.on_combat_end = callback
end

---@param camera Camera
function CombatHandler:set_camera(camera)
  self.camera = camera
end

---@return boolean
function CombatHandler:is_input_locked()
  return self.insert_selection_phase ~= "IDLE"
      or (self.timeline_ui and self.timeline_ui:is_mode_active())
end

--- Start combat
function CombatHandler:start_combat(hero, enemies, spell_book, mana_manager, suspicion_manager)
  self.spell_book = spell_book
  self.mana_manager = mana_manager
  self.suspicion_manager = suspicion_manager
  self.combat_log = {}
  self:_clear_insert_selection()

  self.combat_manager:start_combat(hero, enemies)
  self.combat_manager:set_suspicion_manager(suspicion_manager)
  self.combat_manager:set_on_combat_end(function(result)
    if self.on_combat_end then
      self.on_combat_end(result)
    end
  end)

  -- Enemy HP gauges
  self.enemy_gauges = {}
  for i, enemy in ipairs(enemies) do
    local g = Gauge:new(800, 460 + (i-1) * 35, 180, 25, enemy:get_name(), {0.8, 0.2, 0.2})
    g:set_value(enemy:get_hp(), enemy:get_max_hp())
    table.insert(self.enemy_gauges, g)
  end

  self.hero_gauge:set_value(hero:get_hp(), hero:get_max_hp())

  -- Initialize SpellBookOverlay references
  self.spell_book_overlay:set_spell_book(spell_book)
  self.spell_book_overlay:set_mana_manager(mana_manager)
  self.spell_book_overlay:set_suspicion_manager(suspicion_manager)
  self.spell_book_overlay:set_hero(hero)

  -- Start first planning phase
  self:_start_planning()
end

function CombatHandler:activate()
  self.active = true
end

function CombatHandler:deactivate()
  self.active = false
  self:_clear_insert_selection()
  self.timeline_ui:exit_insert_mode()
  self.spell_book_overlay:set_visible(false)
  self.timeline_ui:set_visible(false)
end

function CombatHandler:update(dt)
  if not self.active then return end

  local tm = self.combat_manager:get_turn_manager()
  if not tm then return end

  local phase = tm:get_phase()

  -- Log timer
  if self.log_timer > 0 then
    self.log_timer = self.log_timer - dt
  end

  -- EXECUTION_PHASE: auto-step through timeline
  if phase == "EXECUTION_PHASE" then
    self.execution_timer = self.execution_timer - dt
    if self.execution_timer <= 0 then
      self:_execute_next()
    end
  end

  -- UI updates
  self.spell_book_overlay:update(dt)
  self.timeline_ui:update(dt)
  self:_update_insert_target_hover()

  -- Gauge updates
  self:_update_gauges()
end

---@return nil
function CombatHandler:_clear_insert_selection()
  self.insert_selection_phase = "IDLE"
  self.pending_insert_spell = nil
  self.pending_insert_target = nil
  self.hovered_insert_target = nil
end

function CombatHandler:draw_world()
  local enemies = self.combat_manager:get_enemies() or {}
  for i, enemy in ipairs(enemies) do
    if enemy:is_alive() then
      local offset_y = (i - 1) * 70
      local enemy_x = self.enemy_world_x
      local enemy_y = self.enemy_world_y + offset_y
      local is_hovered_target = (self.insert_selection_phase == "SELECT_TARGET" and enemy == self.hovered_insert_target)

      if is_hovered_target then
        love.graphics.setColor(1, 0.35, 0.35, 1)
      else
        love.graphics.setColor(0.8, 0.2, 0.2, 1)
      end
      love.graphics.circle('fill', self.enemy_world_x, self.enemy_world_y + offset_y, 30)

      if is_hovered_target then
        love.graphics.setColor(1, 0.9, 0.2, 1)
        love.graphics.setLineWidth(3)
        love.graphics.circle('line', enemy_x, enemy_y, 36)
        love.graphics.setLineWidth(1)
        love.graphics.polygon('fill',
          enemy_x, enemy_y - 52,
          enemy_x - 10, enemy_y - 72,
          enemy_x + 10, enemy_y - 72)
      end

      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.printf(enemy:get_name(), self.enemy_world_x - 50, self.enemy_world_y + offset_y - 45, 100, 'center')
      local intent = enemy:get_intent()
      if intent then
        if intent.type == "attack" then
          love.graphics.setColor(1, 0.4, 0.4, 1)
        else
          love.graphics.setColor(0.4, 0.7, 1, 1)
        end
        love.graphics.printf(intent.description, self.enemy_world_x - 60, self.enemy_world_y + offset_y + 35, 120, 'center')
      end
    end
  end
  love.graphics.setColor(1, 1, 1, 1)
end

function CombatHandler:draw_ui()
  -- Timeline UI (absolute coordinates, outside translate)
  self.timeline_ui:draw()

  -- SpellBookOverlay (absolute coordinates, outside translate)
  self.spell_book_overlay:draw()

  if self.insert_selection_phase == "SELECT_TARGET" then
    love.graphics.setColor(1, 0.85, 0.2, 0.95)
    love.graphics.printf(i18n.t("combat.select_insert_target"), 280, 120, 1000, "center")
  end

  love.graphics.push()
  love.graphics.translate(0, self.ui_offset_y)

  -- Combat log (last 3)
  love.graphics.setColor(1, 1, 1, 0.7)
  local log_y = 30
  local start_idx = math.max(1, #self.combat_log - 2)
  for i = start_idx, #self.combat_log do
    love.graphics.printf(self.combat_log[i], 280, log_y, 1000, 'center')
    log_y = log_y + 18
  end

  -- Gauges
  self.hero_gauge:draw()
  for _, g in ipairs(self.enemy_gauges) do
    g:draw()
  end

  love.graphics.pop()
  love.graphics.setColor(1, 1, 1, 1)
end

function CombatHandler:mousepressed(x, y, button)
  if not self.active then return end

  if self.insert_selection_phase == "SELECT_TARGET" then
    if button == 1 and self.hovered_insert_target and self.pending_insert_spell then
      self.pending_insert_target = self.hovered_insert_target
      self.insert_selection_phase = "SELECT_TIMING"
      self.timeline_ui:enter_insert_mode(self.pending_insert_spell)
    end
    return
  end

  if self.insert_selection_phase == "SELECT_TIMING" then
    if self.timeline_ui:mousepressed(x, y, button) then
      return
    end
    if self.spell_book_overlay:mousepressed_action_buttons(x, y, button) then
      return
    end
    return
  end

  if self.timeline_ui and self.timeline_ui:is_mode_active() then
    if self.timeline_ui:mousepressed(x, y, button) then
      return
    end
    if self.spell_book_overlay:mousepressed_action_buttons(x, y, button) then
      return
    end
    return
  end

  -- SpellBookOverlay (absolute coordinates) - block event propagation
  if self.spell_book_overlay:mousepressed(x, y, button) then return end

  -- Timeline UI (absolute coordinates)
  if self.timeline_ui:mousepressed(x, y, button) then return end
end

function CombatHandler:wheelmoved(x, y)
  if not self.active then return end

  if self.insert_selection_phase == "SELECT_TARGET" then
    return
  end

  if self.insert_selection_phase == "SELECT_TIMING" then
    self.timeline_ui:wheelmoved(x, y)
    return
  end

  if self.timeline_ui and self.timeline_ui:is_mode_active() then
    self.timeline_ui:wheelmoved(x, y)
    return
  end

  local mx, my = love.mouse.getPosition()
  if self.spell_book_overlay.visible and self.spell_book_overlay:hit_test(mx, my) then
    self.spell_book_overlay:wheelmoved(x, y)
  else
    self.timeline_ui:wheelmoved(x, y)
  end
end

--- Start planning phase
function CombatHandler:_start_planning()
  if not self.spell_book or not self.mana_manager then return end

  local tm = self.combat_manager:get_turn_manager()
  if not tm then return end

  self:_clear_insert_selection()
  self.timeline_ui:exit_insert_mode()

  -- Reset spell book for new turn
  self.spell_book:start_planning()
  self.mana_manager:start_planning()

  -- Setup timeline
  local tlm = self.combat_manager:get_timeline_manager()
  if tlm then
    self.timeline_ui:set_timeline_manager(tlm)
  end

  -- Show UI
  self.spell_book_overlay:set_visible(true)
  self.timeline_ui:set_visible(true)

  table.insert(self.combat_log, i18n.t("combat.planning_phase_log", {turn = tm:get_turn_count()}))
end

--- Spell selected from panel: route by timeline_type
---@param spell Spell
function CombatHandler:_on_spell_selected(spell)
  -- Reserve mana first
  if not spell:reserve(self.mana_manager) then return end
  self.spell_book:reserve(spell)

  local timeline_type = spell:get_timeline_type()

  if timeline_type == "insert" then
    self:_begin_insert_selection(spell)
  elseif timeline_type == "global" then
    self.timeline_ui:enter_global_mode(spell)
  else
    -- manipulate_swap, manipulate_remove, manipulate_delay, manipulate_modify
    self.timeline_ui:enter_manipulate_mode(spell)
  end
end

---@param spell Spell
---@return nil
function CombatHandler:_begin_insert_selection(spell)
  self.timeline_ui:exit_insert_mode()
  self.pending_insert_spell = spell
  self.pending_insert_target = nil
  self.hovered_insert_target = nil

  if self:_spell_requires_enemy_target(spell) then
    local tm = self.combat_manager:get_turn_manager()
    local living = tm and tm:get_living_enemies() or {}
    if #living == 0 then
      self.spell_book:unreserve(spell)
      spell:unreserve(self.mana_manager)
      self:_clear_insert_selection()
      table.insert(self.combat_log, i18n.t("combat.no_valid_target", {spell = spell:get_name()}))
      return
    end
    self.insert_selection_phase = "SELECT_TARGET"
    return
  end

  self.pending_insert_target = self:_get_default_insert_target(spell)
  self.insert_selection_phase = "SELECT_TIMING"
  self.timeline_ui:enter_insert_mode(spell)
end

---@param spell Spell
---@return boolean
function CombatHandler:_spell_requires_enemy_target(spell)
  local effect = spell:get_effect()
  if not effect then return false end
  return effect.type == "damage" or effect.type == "debuff_attack" or effect.type == "debuff_speed"
end

---@param spell Spell
---@return Entity|nil
function CombatHandler:_get_default_insert_target(spell)
  local hero = self.combat_manager:get_hero()
  local effect = spell:get_effect()
  if effect and (effect.type == "damage" or effect.type == "debuff_attack" or effect.type == "debuff_speed") then
    local tm = self.combat_manager:get_turn_manager()
    local living = tm and tm:get_living_enemies() or {}
    return living[1]
  end
  if hero and hero:is_alive() then
    return hero
  end
  return nil
end

--- Insert spell at timeline position
---@param spell Spell
---@param insert_index number
---@param target Entity|nil
function CombatHandler:_insert_spell_at(spell, insert_index, target)
  local hero = self.combat_manager:get_hero()
  local enemies = self.combat_manager:get_enemies()
  if not hero or not enemies then return end

  -- Determine target
  local effect = spell:get_effect()
  local resolved_target = target or self.pending_insert_target
  if resolved_target and resolved_target.is_alive and not resolved_target:is_alive() then
    resolved_target = nil
  end

  if not resolved_target then
    resolved_target = self:_get_default_insert_target(spell)
  end
  if not resolved_target then
    self:_clear_insert_selection()
    return
  end

  -- Create predicted action for the spell
  local predicted = PredictedAction:new({
    actor = hero,
    pattern = nil,
    action_type = effect and effect.type or "spell",
    target = resolved_target,
    value = effect and effect.amount or 0,
    source_type = "spell",
    spell = spell,
    description = i18n.t("combat.demon_lord_used_spell", {spell = spell:get_name()}),
  })

  -- Insert into timeline
  local tlm = self.combat_manager:get_timeline_manager()
  if tlm then
    tlm:insert_at(insert_index, spell, predicted)
  end

  table.insert(self.combat_log, i18n.t("combat.spell_placed", {spell = spell:get_name()}))
  self:_clear_insert_selection()
end

--- Handle manipulation spell applied to timeline
---@param spell Spell
---@param target_index number
---@param dest_index number|nil (only for swap)
function CombatHandler:_on_manipulate_applied(spell, target_index, dest_index)
  local tlm = self.combat_manager:get_timeline_manager()
  if not tlm then return end

  local timeline_type = spell:get_timeline_type()

  if timeline_type == "manipulate_swap" and dest_index then
    tlm:swap(target_index, dest_index, spell)
  elseif timeline_type == "manipulate_remove" then
    tlm:remove_at(target_index, spell)
  elseif timeline_type == "manipulate_delay" then
    local effect = spell:get_effect()
    local positions = effect and effect.amount or 1
    tlm:delay_at(target_index, positions, spell)
  elseif timeline_type == "manipulate_modify" then
    tlm:modify_at(target_index, spell)
  end

  table.insert(self.combat_log, i18n.t("combat.manipulate_applied", {spell = spell:get_name()}))
end

--- Handle global spell applied to entire timeline
---@param spell Spell
function CombatHandler:_on_global_applied(spell)
  local tlm = self.combat_manager:get_timeline_manager()
  if not tlm then return end

  tlm:apply_global(spell)
  table.insert(self.combat_log, i18n.t("combat.global_applied", {spell = spell:get_name()}))
end

--- Confirm planning: transition to execution
function CombatHandler:_confirm_planning()
  local tlm = self.combat_manager:get_timeline_manager()
  self:_clear_insert_selection()

  -- Manipulate/global cards don't create spell actions in execution,
  -- so apply suspicion once at confirm time.
  if tlm and self.suspicion_manager then
    for _, intervention in ipairs(tlm:get_interventions()) do
      if intervention.spell and intervention.type ~= "insert" then
        local delta = intervention.spell:get_suspicion_delta() or 0
        if delta > 0 then
          self.suspicion_manager:add(delta)
        elseif delta < 0 then
          self.suspicion_manager:reduce(math.abs(delta))
        end
      end
    end
  end

  -- Confirm spell book (reserved → used)
  self.spell_book:confirm()

  -- Confirm timeline
  if tlm then
    tlm:confirm()
  end

  -- Hide planning UI
  self.spell_book_overlay:set_visible(false)

  -- Start execution
  self.combat_manager:start_execution()
  self.execution_timer = self.execution_delay

  table.insert(self.combat_log, i18n.t("combat.execution_start"))
end

--- Reset planning: unreserve all spells and refund mana
function CombatHandler:_reset_planning()
  self:_clear_insert_selection()

  -- Unreserve spells from spell book
  local released = self.spell_book:unreserve_all()
  for _, spell in ipairs(released) do
    spell:unreserve(self.mana_manager)
  end

  -- Reset timeline
  local tlm = self.combat_manager:get_timeline_manager()
  if tlm then
    tlm:reset()
  end

  -- Exit insert mode if active
  self.timeline_ui:exit_insert_mode()

  table.insert(self.combat_log, i18n.t("combat.planning_reset"))
end

--- Execute next timeline action
function CombatHandler:_execute_next()
  if self.combat_manager:is_execution_done() then
    self:_on_execution_complete()
    return
  end

  local action = self.combat_manager:execute_next_action()
  if action then
    table.insert(self.combat_log, action:get_description())
    self:_update_gauges()
  end

  -- Check combat over
  if self.combat_manager:is_combat_over() then
    self.combat_manager:end_combat()
    return
  end

  -- Check if execution is done
  if self.combat_manager:is_execution_done() then
    self.execution_timer = self.execution_delay
  else
    self.execution_timer = self.execution_delay
  end
end

--- Execution complete: start next planning phase
function CombatHandler:_on_execution_complete()
  if self.combat_manager:is_combat_over() then
    self.combat_manager:end_combat()
    return
  end

  -- Next planning phase
  self.combat_manager:next_planning()
  self:_start_planning()
end

---@return nil
function CombatHandler:_update_insert_target_hover()
  self.hovered_insert_target = nil

  if self.insert_selection_phase ~= "SELECT_TARGET" then
    return
  end
  if not self.pending_insert_spell or not self:_spell_requires_enemy_target(self.pending_insert_spell) then
    return
  end

  local mx, my = love.mouse.getPosition()
  self.hovered_insert_target = self:_get_hovered_enemy_target(mx, my)
end

---@param sx number
---@param sy number
---@return number
---@return number
function CombatHandler:_screen_to_world(sx, sy)
  if self.camera then
    return self.camera:screen_to_world(sx, sy)
  end
  return sx, sy
end

---@param mx number
---@param my number
---@return Enemy|nil
function CombatHandler:_get_hovered_enemy_target(mx, my)
  local world_x, world_y = self:_screen_to_world(mx, my)
  local enemies = self.combat_manager:get_enemies() or {}
  local best_enemy = nil
  local best_dist2 = nil
  local hit_radius = 36
  local hit_radius2 = hit_radius * hit_radius

  for i, enemy in ipairs(enemies) do
    if enemy:is_alive() then
      local ey = self.enemy_world_y + (i - 1) * 70
      local dx = world_x - self.enemy_world_x
      local dy = world_y - ey
      local dist2 = dx * dx + dy * dy
      if dist2 <= hit_radius2 and (not best_dist2 or dist2 < best_dist2) then
        best_enemy = enemy
        best_dist2 = dist2
      end
    end
  end

  return best_enemy
end

--- Update gauges
function CombatHandler:_update_gauges()
  local hero = self.combat_manager:get_hero()
  if hero then
    self.hero_gauge:set_value(hero:get_hp(), hero:get_max_hp())
  end

  local enemies = self.combat_manager:get_enemies() or {}
  for i, enemy in ipairs(enemies) do
    if self.enemy_gauges[i] then
      self.enemy_gauges[i]:set_value(enemy:get_hp(), enemy:get_max_hp())
    end
  end
end

return CombatHandler
