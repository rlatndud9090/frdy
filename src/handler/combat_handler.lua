local class = require('lib.middleclass')
local CombatManager = require('src.combat.combat_manager')
local PredictedAction = require('src.combat.predicted_action')
local Gauge = require('src.ui.gauge')
local Button = require('src.ui.button')
local SpellPanel = require('src.ui.spell_panel')
local TimelineUI = require('src.ui.timeline_ui')
local i18n = require('src.i18n.init')

---@class CombatHandler
---@field combat_manager CombatManager
---@field spell_book SpellBook|nil
---@field mana_manager ManaManager|nil
---@field suspicion_manager SuspicionManager|nil
---@field hero_gauge Gauge
---@field enemy_gauges Gauge[]
---@field confirm_button Button
---@field reset_button Button
---@field spell_panel SpellPanel
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
local CombatHandler = class('CombatHandler')

function CombatHandler:initialize()
  self.combat_manager = CombatManager:new()
  self.spell_book = nil
  self.mana_manager = nil
  self.suspicion_manager = nil

  -- UI
  self.hero_gauge = Gauge:new(50, 520, 200, 25, "entity.hero", {0.2, 0.8, 0.2})
  self.enemy_gauges = {}

  -- Confirm button
  self.confirm_button = Button:new(1100, 580, 120, 40, "ui.confirm")
  self.confirm_button:set_on_click(function()
    self:_confirm_planning()
  end)
  self.confirm_button:set_visible(false)

  -- Reset button
  self.reset_button = Button:new(1100, 630, 120, 40, "ui.reset")
  self.reset_button:set_on_click(function()
    self:_reset_planning()
  end)
  self.reset_button:set_visible(false)

  -- Spell panel
  self.spell_panel = SpellPanel:new()
  self.spell_panel:set_visible(false)
  self.spell_panel:set_on_play(function(spell, index)
    self:_on_spell_selected(spell, index)
  end)

  -- Timeline UI
  self.timeline_ui = TimelineUI:new()
  self.timeline_ui:set_visible(false)
  self.timeline_ui:set_on_insert(function(spell, insert_index)
    self:_insert_spell_at(spell, insert_index)
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
end

function CombatHandler:set_on_combat_end(callback)
  self.on_combat_end = callback
end

--- Start combat
function CombatHandler:start_combat(hero, enemies, spell_book, mana_manager, suspicion_manager)
  self.spell_book = spell_book
  self.mana_manager = mana_manager
  self.suspicion_manager = suspicion_manager
  self.combat_log = {}

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

  -- Start first planning phase
  self:_start_planning()
end

function CombatHandler:activate()
  self.active = true
end

function CombatHandler:deactivate()
  self.active = false
  self.spell_panel:set_visible(false)
  self.timeline_ui:set_visible(false)
  self.confirm_button:set_visible(false)
  self.reset_button:set_visible(false)
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
  self.spell_panel:update(dt)
  self.timeline_ui:update(dt)
  self.confirm_button:update(dt)
  self.reset_button:update(dt)

  -- Gauge updates
  self:_update_gauges()
end

function CombatHandler:draw_world()
  local enemies = self.combat_manager:get_enemies() or {}
  for i, enemy in ipairs(enemies) do
    if enemy:is_alive() then
      local offset_y = (i - 1) * 70
      love.graphics.setColor(0.8, 0.2, 0.2, 1)
      love.graphics.circle('fill', self.enemy_world_x, self.enemy_world_y + offset_y, 30)
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
  -- Timeline UI (drawn outside ui_offset_y translate)
  self.timeline_ui:draw()

  love.graphics.push()
  love.graphics.translate(0, self.ui_offset_y)

  local tm = self.combat_manager:get_turn_manager()
  local phase = tm and tm:get_phase() or ""
  local turn_count = tm and tm:get_turn_count() or 0

  -- Phase info
  love.graphics.setColor(1, 1, 1, 0.9)
  local phase_text = i18n.t("combat.in_combat")
  if phase == "PLANNING_PHASE" then
    phase_text = i18n.t("combat.planning_phase", {turn = turn_count})
  elseif phase == "EXECUTION_PHASE" then
    phase_text = i18n.t("combat.execution_phase")
  end
  love.graphics.printf(phase_text, 0, 20, 1280, 'center')

  -- Mana display
  if self.mana_manager then
    love.graphics.setColor(0, 0.5, 1, 1)
    love.graphics.printf(
      i18n.t("combat.mana_display", {current = self.mana_manager:get_current(), max = self.mana_manager:get_max()}),
      0, 45, 1280, 'center'
    )
  end

  -- Gauges
  self.hero_gauge:draw()
  for _, g in ipairs(self.enemy_gauges) do
    g:draw()
  end

  -- Combat log (last 3)
  love.graphics.setColor(1, 1, 1, 0.7)
  local log_y = 70
  local start_idx = math.max(1, #self.combat_log - 2)
  for i = start_idx, #self.combat_log do
    love.graphics.printf(self.combat_log[i], 300, log_y, 680, 'center')
    log_y = log_y + 18
  end

  -- SpellPanel + Buttons
  self.spell_panel:draw()
  self.confirm_button:draw()
  self.reset_button:draw()

  love.graphics.pop()
  love.graphics.setColor(1, 1, 1, 1)
end

function CombatHandler:mousepressed(x, y, button)
  if not self.active then return end

  -- Timeline UI uses absolute coordinates
  self.timeline_ui:mousepressed(x, y, button)

  local adjusted_y = y - self.ui_offset_y
  self.spell_panel:mousepressed(x, adjusted_y, button)
  self.confirm_button:mousepressed(x, adjusted_y, button)
  self.reset_button:mousepressed(x, adjusted_y, button)
end

function CombatHandler:wheelmoved(x, y)
  if not self.active then return end
  self.timeline_ui:wheelmoved(x, y)
end

--- Start planning phase
function CombatHandler:_start_planning()
  if not self.spell_book or not self.mana_manager then return end

  local tm = self.combat_manager:get_turn_manager()
  if not tm then return end

  -- Reset spell book for new turn
  self.spell_book:start_planning()
  self.mana_manager:start_planning()

  -- Setup timeline
  local tlm = self.combat_manager:get_timeline_manager()
  if tlm then
    self.timeline_ui:set_timeline_manager(tlm)
  end

  -- Show UI
  self.spell_panel:set_spell_book(self.spell_book)
  self.spell_panel:set_mana_manager(self.mana_manager)
  self.spell_panel:set_visible(true)
  self.timeline_ui:set_visible(true)
  self.confirm_button:set_visible(true)
  self.reset_button:set_visible(true)

  table.insert(self.combat_log, i18n.t("combat.planning_phase_log", {turn = tm:get_turn_count()}))
end

--- Spell selected from panel: enter insert mode on timeline
---@param spell Spell
---@param index number
function CombatHandler:_on_spell_selected(spell, index)
  local timeline_type = spell:get_timeline_type()

  if timeline_type == "insert" then
    -- Reserve mana
    if not spell:reserve(self.mana_manager) then return end
    self.spell_book:reserve(spell)

    -- Enter timeline insert mode
    self.timeline_ui:enter_insert_mode(spell)
  else
    -- For manipulate/global types, handle directly (expanded in Step 5-3B)
    if not spell:reserve(self.mana_manager) then return end
    self.spell_book:reserve(spell)
  end
end

--- Insert spell at timeline position
---@param spell Spell
---@param insert_index number
function CombatHandler:_insert_spell_at(spell, insert_index)
  local hero = self.combat_manager:get_hero()
  local enemies = self.combat_manager:get_enemies()
  if not hero or not enemies then return end

  -- Determine target
  local effect = spell:get_effect()
  local target = hero
  if effect and (effect.type == "damage" or effect.type == "debuff_attack") then
    local living = self.combat_manager:get_turn_manager():get_living_enemies()
    if #living > 0 then
      target = living[1]
    end
  end

  -- Create predicted action for the spell
  local predicted = PredictedAction:new({
    actor = hero,
    pattern = nil,
    action_type = effect and effect.type or "spell",
    target = target,
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
end

--- Confirm planning: transition to execution
function CombatHandler:_confirm_planning()
  -- Confirm spell book (reserved → used)
  self.spell_book:confirm()

  -- Confirm timeline
  local tlm = self.combat_manager:get_timeline_manager()
  if tlm then
    tlm:confirm()
  end

  -- Hide planning UI
  self.spell_panel:set_visible(false)
  self.confirm_button:set_visible(false)
  self.reset_button:set_visible(false)

  -- Start execution
  self.combat_manager:start_execution()
  self.execution_timer = self.execution_delay

  table.insert(self.combat_log, i18n.t("combat.execution_start"))
end

--- Reset planning: unreserve all spells and refund mana
function CombatHandler:_reset_planning()
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
