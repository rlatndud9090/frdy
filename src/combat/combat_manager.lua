local class = require('lib.middleclass')
local TurnManager = require('src.combat.turn_manager')
local ActionQueue = require('src.combat.action_queue')
local PredictionEngine = require('src.combat.prediction_engine')
local TimelineManager = require('src.combat.timeline_manager')

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
end

---@param hero Hero
---@param enemies Enemy[]
function CombatManager:start_combat(hero, enemies)
  self.hero = hero
  self.enemies = enemies
  self.turn_manager = TurnManager:new(hero, enemies)
  self.action_queue = ActionQueue:new()
  self.prediction_engine = PredictionEngine:new(20)
  self.timeline_manager = TimelineManager:new(self.prediction_engine)
  self.timeline_manager:setup(hero, enemies)
  self.state = "active"
  self.execution_index = 0
  self.turn_manager:prepare_enemy_intents()
end

function CombatManager:end_combat()
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

--- Start execution phase: prepare to step through timeline
function CombatManager:start_execution()
  self.turn_manager:start_execution()
  self.execution_index = 0
end

---Execute pattern action.
---Attack actions must execute from live actor stats because insert spells can
---change attack between timeline generation and execution.
---@param action PredictedAction
---@param actor Entity
---@param target Entity
function CombatManager:_execute_pattern_action(action, actor, target)
  if not action.pattern then return end

  if action.pattern.type == "attack" then
    action.pattern:execute(actor, target)
    return
  end

  local value = action:get_value()

  if action.pattern.type == "defend" and value then
    actor.defense = actor.defense + value
    return
  end

  if action.pattern.type == "heal" and value then
    actor:heal(value)
    return
  end

  action.pattern:execute(actor, target)
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
  if source == "hero" then
    if action.pattern and action.target and action.target:is_alive() then
      self:_execute_pattern_action(action, self.hero, action.target)
    end
  elseif source == "enemy" then
    if action.pattern and action.actor and action.actor:is_alive() then
      if action.pattern.type == "attack" then
        self:_execute_pattern_action(action, action.actor, self.hero)
      elseif action.pattern.type == "defend" then
        self:_execute_pattern_action(action, action.actor, action.actor)
      end
    end
  elseif source == "spell" then
    if action.spell and action.target then
      local context = {
        hero = self.hero,
        enemies = self.enemies,
        suspicion_manager = self._suspicion_manager,
      }
      action.spell:execute(action.target, context)
    end
  end

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
  self.turn_manager:next_planning()
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

---@param callback function
function CombatManager:set_on_combat_end(callback)
  self.on_combat_end = callback
end

return CombatManager
