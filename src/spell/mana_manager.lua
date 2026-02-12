local class = require('lib.middleclass')

---@class ManaManager
---@field current_mana number
---@field max_mana number
---@field reserved_mana number
---@field new fun(self: ManaManager, max_mana?: number): ManaManager
local ManaManager = class('ManaManager')

---@param max_mana? number
function ManaManager:initialize(max_mana)
  self.max_mana = max_mana or 100
  self.current_mana = self.max_mana
  self.reserved_mana = 0
end

---@return number
function ManaManager:get_current()
  return self.current_mana
end

---@return number
function ManaManager:get_max()
  return self.max_mana
end

---@return number
function ManaManager:get_reserved()
  return self.reserved_mana
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

--- Reserve mana (for timeline placement)
---@param amount number
---@return boolean
function ManaManager:reserve(amount)
  if not self:can_afford(amount) then
    return false
  end
  self.current_mana = self.current_mana - amount
  self.reserved_mana = self.reserved_mana + amount
  return true
end

--- Unreserve mana (refund from timeline removal)
---@param amount number
function ManaManager:unreserve(amount)
  self.current_mana = self.current_mana + amount
  self.reserved_mana = math.max(0, self.reserved_mana - amount)
end

--- Reset reserved tracking for new planning phase
function ManaManager:start_planning()
  self.reserved_mana = 0
end

--- Recover mana after combat (capped at max)
---@param amount number
function ManaManager:recover_after_combat(amount)
  self.current_mana = math.min(self.max_mana, self.current_mana + amount)
end

return ManaManager
