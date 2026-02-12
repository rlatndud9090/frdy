local class = require('lib.middleclass')

---@class TurnManager
---@field hero Hero
---@field enemies Enemy[]
---@field phase string "PLANNING_PHASE"|"EXECUTION_PHASE"
---@field turn_count number
local TurnManager = class('TurnManager')

---@param hero Hero
---@param enemies Enemy[]
function TurnManager:initialize(hero, enemies)
  self.hero = hero
  self.enemies = enemies
  self.phase = "PLANNING_PHASE"
  self.turn_count = 1
end

---@return string
function TurnManager:get_phase()
  return self.phase
end

---@return number
function TurnManager:get_turn_count()
  return self.turn_count
end

--- Transition to execution phase
function TurnManager:start_execution()
  self.phase = "EXECUTION_PHASE"
end

--- Transition to next planning phase (new turn)
function TurnManager:next_planning()
  self.turn_count = self.turn_count + 1
  self.phase = "PLANNING_PHASE"
  self:prepare_enemy_intents()
end

---@return Enemy[]
function TurnManager:get_living_enemies()
  local living = {}
  for _, enemy in ipairs(self.enemies) do
    if enemy:is_alive() then
      living[#living + 1] = enemy
    end
  end
  return living
end

function TurnManager:prepare_enemy_intents()
  for _, enemy in ipairs(self.enemies) do
    if enemy:is_alive() then
      enemy:prepare_intent()
    end
  end
end

return TurnManager
