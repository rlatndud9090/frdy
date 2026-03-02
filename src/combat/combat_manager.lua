local class = require('lib.middleclass')
local TurnManager = require('src.combat.turn_manager')
local ActionQueue = require('src.combat.action_queue')
local PredictionEngine = require('src.combat.prediction_engine')
local TimelineManager = require('src.combat.timeline_manager')
local StatusContainer = require('src.combat.status_container')

---@class CombatManager
---@field hero Hero|nil
---@field enemies Enemy[]|nil
---@field turn_manager TurnManager|nil
---@field action_queue ActionQueue|nil
---@field prediction_engine PredictionEngine|nil
---@field timeline_manager TimelineManager|nil
---@field state string
---@field on_combat_end function|nil
---@field execution_index number
---@field _suspicion_manager SuspicionManager|nil
---@field _demon_awakening DemonAwakening|nil
---@field field_status_container StatusContainer|nil
---@field _temp_defense_bonuses table<Entity, number>
local CombatManager = class('CombatManager')

function CombatManager:initialize()
  self.hero = nil
  self.enemies = nil
  self.turn_manager = nil
  self.action_queue = nil
  self.prediction_engine = nil
  self.timeline_manager = nil
  self.state = "idle"
  self.on_combat_end = nil
  self.execution_index = 0
  self._suspicion_manager = nil
  self._demon_awakening = nil
  self.field_status_container = nil
  self._temp_defense_bonuses = {}
end

---@param hero Hero
---@param enemies Enemy[]
function CombatManager:start_combat(hero, enemies)
  self.hero = hero
  self.enemies = enemies
  self._temp_defense_bonuses = {}
  self.field_status_container = StatusContainer:new(self, "field")
  self.turn_manager = TurnManager:new(hero, enemies)
  self.action_queue = ActionQueue:new()
  self.prediction_engine = PredictionEngine:new(20)
  self.prediction_engine:set_field_status_container(self.field_status_container)
  self.timeline_manager = TimelineManager:new(self.prediction_engine)
  self.timeline_manager:setup(hero, enemies)
  self.state = "active"
  self.execution_index = 0
  if self.hero and self.hero.reset_action_state then
    self.hero:reset_action_state()
    self.hero:set_current_turn(self.turn_manager:get_turn_count())
  end
  self.turn_manager:prepare_enemy_intents()
end

function CombatManager:end_combat()
  self:_clear_temp_defense_bonuses()
  if self.on_combat_end then
    self.on_combat_end(self.state)
  end
end

---@return boolean
function CombatManager:is_combat_over()
  return self.state == "victory" or self.state == "defeat"
end

---@return string
function CombatManager:get_state()
  return self.state
end

---@return TurnManager|nil
function CombatManager:get_turn_manager()
  return self.turn_manager
end

---@return Hero|nil
function CombatManager:get_hero()
  return self.hero
end

---@return Enemy[]|nil
function CombatManager:get_enemies()
  return self.enemies
end

---@return TimelineManager|nil
function CombatManager:get_timeline_manager()
  return self.timeline_manager
end

---@return PredictionEngine|nil
function CombatManager:get_prediction_engine()
  return self.prediction_engine
end

---@return StatusContainer|nil
function CombatManager:get_field_status_container()
  return self.field_status_container
end

---@param container StatusContainer|nil
---@param hook_name string
---@param ctx table
---@return nil
function CombatManager:_emit_hook_to_container(container, hook_name, ctx)
  if container then
    container:emit(hook_name, ctx)
  end
end

---@param entity Entity|nil
---@return StatusContainer|nil
function CombatManager:_get_entity_status_container(entity)
  if not entity or type(entity) ~= "table" then
    return nil
  end
  return entity.status_container
end

---@param hook_name string
---@param ctx table
---@param source_entity Entity|nil
---@param target_entity Entity|nil
---@return nil
function CombatManager:_emit_status_hook(hook_name, ctx, source_entity, target_entity)
  self:_emit_hook_to_container(self.field_status_container, hook_name, ctx)
  self:_emit_hook_to_container(self:_get_entity_status_container(source_entity), hook_name, ctx)
  if target_entity and target_entity ~= source_entity then
    self:_emit_hook_to_container(self:_get_entity_status_container(target_entity), hook_name, ctx)
  end
end

---@param target Entity|nil
---@param amount number
---@param source_entity Entity|nil
---@param action_ctx table|nil
---@return number
function CombatManager:_apply_damage(target, amount, source_entity, action_ctx)
  if not target or not target.is_alive or not target:is_alive() then
    return 0
  end

  local damage_ctx = {
    amount = math.max(0, amount or 0),
    source = source_entity,
    target = target,
    action_context = action_ctx,
    canceled = false,
  }
  self:_emit_status_hook("before_damage", damage_ctx, source_entity, target)
  if damage_ctx.canceled or (damage_ctx.amount or 0) <= 0 then
    return 0
  end

  local actual = target:take_damage(damage_ctx.amount)
  damage_ctx.actual = actual
  self:_emit_status_hook("after_damage", damage_ctx, source_entity, target)
  return actual
end

---@param target Entity|nil
---@param amount number
---@param source_entity Entity|nil
---@param action_ctx table|nil
---@return number
function CombatManager:_apply_heal(target, amount, source_entity, action_ctx)
  if not target or not target.is_alive or not target:is_alive() then
    return 0
  end

  local heal_ctx = {
    amount = math.max(0, amount or 0),
    source = source_entity,
    target = target,
    action_context = action_ctx,
    canceled = false,
  }
  self:_emit_status_hook("before_heal", heal_ctx, source_entity, target)
  if heal_ctx.canceled or (heal_ctx.amount or 0) <= 0 then
    return 0
  end

  local before = target:get_hp()
  target:heal(heal_ctx.amount)
  local actual = math.max(0, target:get_hp() - before)
  heal_ctx.actual = actual
  self:_emit_status_hook("after_heal", heal_ctx, source_entity, target)
  return actual
end

---@param action PredictedAction
---@param source string
---@param action_type string
---@param value number
---@return table
function CombatManager:_build_action_context(action, source, action_type, value)
  local actor = action.actor
  return {
    action = action,
    source = source,
    action_type = action_type,
    value = value,
    actor = actor,
    target = action.target,
    hero = self.hero,
    enemies = self.enemies,
    canceled = false,
    blocked = action.blocked == true,
    executed = false,
    apply_damage = function(target, amount, source_override, parent_ctx)
      return self:_apply_damage(target, amount, source_override or actor, parent_ctx or action)
    end,
    apply_heal = function(target, amount, source_override, parent_ctx)
      return self:_apply_heal(target, amount, source_override or actor, parent_ctx or action)
    end,
  }
end

---@param action_ctx table
---@param source_entity Entity|nil
---@return nil
function CombatManager:_consume_action_statuses(action_ctx, source_entity)
  if source_entity and source_entity.status_container then
    source_entity.status_container:consume_action()
  end
  if self.field_status_container then
    self.field_status_container:consume_action()
  end
end

---@param actor Entity|nil
---@param bonus number
---@return nil
function CombatManager:_apply_temp_defense_bonus(actor, bonus)
  if not actor or type(actor) ~= "table" then
    return
  end
  local amount = math.max(0, math.floor(bonus or 0))
  if amount <= 0 then
    return
  end
  actor.defense = (actor.defense or 0) + amount
  self._temp_defense_bonuses[actor] = (self._temp_defense_bonuses[actor] or 0) + amount
end

---@return nil
function CombatManager:_clear_temp_defense_bonuses()
  for actor, bonus in pairs(self._temp_defense_bonuses or {}) do
    if actor and type(actor) == "table" and type(actor.defense) == "number" then
      actor.defense = math.max(0, actor.defense - bonus)
    end
  end
  self._temp_defense_bonuses = {}
end

---@return nil
function CombatManager:_tick_status_turns()
  if self.field_status_container then
    self.field_status_container:consume_turn()
  end

  if self.hero and self.hero.status_container then
    self.hero.status_container:consume_turn()
  end

  for _, enemy in ipairs(self.enemies or {}) do
    if enemy and enemy.status_container then
      enemy.status_container:consume_turn()
    end
  end
end

--- Start execution phase: prepare to step through timeline
function CombatManager:start_execution()
  self.turn_manager:start_execution()
  self.execution_index = 0
end

--- Execute next action in timeline
---@return PredictedAction|nil action that was executed, or nil if done
function CombatManager:execute_next_action()
  if not self.timeline_manager then return nil end

  self.execution_index = self.execution_index + 1
  local action = self.timeline_manager:get_action(self.execution_index)

  if not action then
    return nil
  end

  local source = action:get_source_type()
  local action_type = action:get_action_type()
  local value = math.max(0, action:get_value() or 0)
  local action_ctx = self:_build_action_context(action, source, action_type, value)
  self:_emit_status_hook("before_action_attempt", action_ctx, action_ctx.actor, action_ctx.target)
  if action_ctx.canceled then
    action.blocked = true
  end

  if action.blocked then
    if source == "enemy" and action.actor and action.actor:is_alive() and action.actor.consume_action then
      action.actor:consume_action()
    end
    local desc = action:get_description() or ""
    if desc == "" then
      action.description = "[BLOCKED]"
    else
      action.description = desc .. " [BLOCKED]"
    end
  else
    if source == "hero" then
      if self.hero:is_alive() then
        local hero_pattern_executed = false
        if action_type == "attack" then
          if action.target and action.target:is_alive() then
            self:_apply_damage(action.target, value, self.hero, action_ctx)
            hero_pattern_executed = true
          end
        elseif action_type == "defend" then
          self:_apply_temp_defense_bonus(self.hero, value)
          hero_pattern_executed = true
        elseif action_type == "heal" then
          self:_apply_heal(self.hero, value, self.hero, action_ctx)
          hero_pattern_executed = true
        elseif action.pattern and action.target and action.target:is_alive() then
          action.pattern:execute(self.hero, action.target)
          hero_pattern_executed = true
        end
        if hero_pattern_executed and action.pattern and self.hero.mark_pattern_used then
          local turn_count = self.turn_manager and self.turn_manager:get_turn_count() or 0
          self.hero:mark_pattern_used(action.pattern.id, turn_count)
        end
      end
    elseif source == "enemy" then
      if action.actor and action.actor:is_alive() then
        if action_type == "attack" then
          if self.hero:is_alive() then
            self:_apply_damage(self.hero, value, action.actor, action_ctx)
          end
        elseif action_type == "defend" then
          self:_apply_temp_defense_bonus(action.actor, value)
        elseif action_type == "heal" then
          self:_apply_heal(action.actor, value, action.actor, action_ctx)
        elseif action.pattern then
          if action.pattern.type == "attack" then
            action.pattern:execute(action.actor, self.hero)
          elseif action.pattern.type == "defend" then
            action.pattern:execute(action.actor, action.actor)
          end
        end

        -- 적 행동이 실제로 실행된 시점에만 패턴 커서를 소비한다.
        if action.actor.consume_action then
          action.actor:consume_action()
        end
      end
    elseif source == "spell" then
      if action.spell then
        local spell_source = action.actor or self.hero
        local context = {
          hero = self.hero,
          enemies = self.enemies,
          suspicion_manager = self._suspicion_manager,
          demon_awakening = self._demon_awakening,
          field_statuses = self.field_status_container,
          apply_damage = function(target, amount, source_override, parent_ctx)
            return self:_apply_damage(target, amount, source_override or spell_source, parent_ctx or action_ctx)
          end,
          apply_heal = function(target, amount, source_override, parent_ctx)
            return self:_apply_heal(target, amount, source_override or spell_source, parent_ctx or action_ctx)
          end,
        }
        action.spell:execute(action.target, context)
      end
    end
  end

  action_ctx.executed = not action.blocked
  self:_emit_status_hook("after_action_committed", action_ctx, action_ctx.actor, action_ctx.target)
  self:_consume_action_statuses(action_ctx, action_ctx.actor)

  -- Check victory/defeat
  local living = self.turn_manager:get_living_enemies()
  if #living == 0 then
    self.state = "victory"
  elseif not self.hero:is_alive() then
    self.state = "defeat"
  end

  return action
end

--- Check if execution is complete
---@return boolean
function CombatManager:is_execution_done()
  if not self.timeline_manager then return true end
  return self.execution_index >= self.timeline_manager:get_count()
      or self:is_combat_over()
end

--- Start next planning phase
function CombatManager:next_planning()
  self:_clear_temp_defense_bonuses()
  self:_tick_status_turns()
  self.turn_manager:next_planning()
  if self.hero and self.hero.set_current_turn then
    self.hero:set_current_turn(self.turn_manager:get_turn_count())
  end
  self.execution_index = 0
  if self.timeline_manager then
    self.timeline_manager:setup(self.hero, self.enemies)
  end
end

--- Set suspicion manager reference for spell execution
---@param sm SuspicionManager
function CombatManager:set_suspicion_manager(sm)
  self._suspicion_manager = sm
end

---@param awakening DemonAwakening|nil
function CombatManager:set_demon_awakening(awakening)
  self._demon_awakening = awakening
end

---@param callback function
function CombatManager:set_on_combat_end(callback)
  self.on_combat_end = callback
end

return CombatManager
