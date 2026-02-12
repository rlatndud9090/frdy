local class = require('lib.middleclass')

---@class SuspicionManager
---@field level number
---@field max_level number
---@field event_bus EventBus|nil
---@field new fun(self: SuspicionManager, event_bus?: EventBus): SuspicionManager
local SuspicionManager = class('SuspicionManager')

---@param event_bus? EventBus
function SuspicionManager:initialize(event_bus)
  self.level = 0
  self.max_level = 100
  self.event_bus = event_bus
end

---@return number
function SuspicionManager:get_level()
  return self.level
end

---@return number
function SuspicionManager:get_max()
  return self.max_level
end

---@return number
function SuspicionManager:get_ratio()
  return self.level / self.max_level
end

--- Add suspicion, clamped to max_level
---@param amount number
function SuspicionManager:add(amount)
  local old_level = self.level
  self.level = math.min(self.max_level, self.level + amount)

  if self.event_bus then
    self.event_bus:emit("suspicion_change", {
      old_level = old_level,
      new_level = self.level,
      delta = amount
    })
  end

  if self:is_max() and self.event_bus then
    self.event_bus:emit("suspicion_max", {
      level = self.level
    })
  end
end

--- Reduce suspicion, clamped to 0
---@param amount number
function SuspicionManager:reduce(amount)
  local old_level = self.level
  self.level = math.max(0, self.level - amount)

  if self.event_bus then
    self.event_bus:emit("suspicion_change", {
      old_level = old_level,
      new_level = self.level,
      delta = -amount
    })
  end
end

--- Check if suspicion has reached maximum
---@return boolean
function SuspicionManager:is_max()
  return self.level >= self.max_level
end

return SuspicionManager
