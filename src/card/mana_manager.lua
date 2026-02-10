local class = require('lib.middleclass')

---@class ManaManager
---@field current_mana number
---@field max_mana number
---@field turn_mana number
---@field new fun(self: ManaManager, initial_max?: number): ManaManager
local ManaManager = class('ManaManager')

---@param initial_max? number
function ManaManager:initialize(initial_max)
  self.max_mana = initial_max or 3
  self.current_mana = self.max_mana
  self.turn_mana = self.max_mana
end

---@return number
function ManaManager:get_current()
  return self.current_mana
end

---@return number
function ManaManager:get_max()
  return self.max_mana
end

--- Check if the player can afford a cost
---@param cost number
---@return boolean
function ManaManager:can_afford(cost)
  return self.current_mana >= cost
end

--- Spend mana
---@param amount number
---@return boolean
function ManaManager:spend(amount)
  if not self:can_afford(amount) then
    return false
  end
  self.current_mana = self.current_mana - amount
  return true
end

--- Restore mana up to max
---@param amount number
function ManaManager:restore(amount)
  self.current_mana = math.min(self.max_mana, self.current_mana + amount)
end

--- Start a new turn: set mana based on turn count (capped at 10)
---@param turn_count number
function ManaManager:start_turn(turn_count)
  self.turn_mana = math.min(10, turn_count)
  self.max_mana = self.turn_mana
  self.current_mana = self.turn_mana
end

return ManaManager
