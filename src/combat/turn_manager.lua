local class = require('lib.middleclass')

---@class TurnManager
---@field hero Hero
---@field enemies Enemy[]
---@field phase string
---@field turn_count number
local TurnManager = class('TurnManager')

---@param hero Hero
---@param enemies Enemy[]
function TurnManager:initialize(hero, enemies)
  self.hero = hero
  self.enemies = enemies
  self.phase = "DEMON_LORD_TURN"
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

---@return Entity|nil
function TurnManager:get_current_entity()
  if self.phase == "DEMON_LORD_TURN" then
    return nil
  elseif self.phase == "HERO_TURN" then
    return self.hero
  elseif self.phase == "ENEMY_TURN" then
    return self.enemies[1]
  end
  return nil
end

function TurnManager:next_turn()
  if self.phase == "DEMON_LORD_TURN" then
    self.phase = "HERO_TURN"
  elseif self.phase == "HERO_TURN" then
    self.phase = "ENEMY_TURN"
  elseif self.phase == "ENEMY_TURN" then
    self.phase = "DEMON_LORD_TURN"
    self.turn_count = self.turn_count + 1
    self:prepare_enemy_intents()
  end
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
