local class = require('lib.middleclass')

---@class DemonAwakening
---@field threshold number
---@field progress number
---@field pending_rewards number
---@field total_spent number
local DemonAwakening = class('DemonAwakening')

---@param config? {threshold?: number}
function DemonAwakening:initialize(config)
  config = config or {}
  self.threshold = math.max(1, math.floor(config.threshold or 100))
  self.progress = 0
  self.pending_rewards = 0
  self.total_spent = 0
end

---@param mana_cost number
---@return number newly_gained_rewards
function DemonAwakening:on_spell_executed(mana_cost)
  local gain = math.max(0, math.floor(mana_cost or 0))
  if gain <= 0 then
    return 0
  end

  self.total_spent = self.total_spent + gain
  self.progress = self.progress + gain

  local gained = 0
  while self.progress >= self.threshold do
    self.progress = self.progress - self.threshold
    self.pending_rewards = self.pending_rewards + 1
    gained = gained + 1
  end

  return gained
end

---@return number
function DemonAwakening:consume_pending_rewards()
  local pending = self.pending_rewards
  self.pending_rewards = 0
  return pending
end

---@return number
function DemonAwakening:get_progress()
  return self.progress
end

---@return number
function DemonAwakening:get_threshold()
  return self.threshold
end

---@return number
function DemonAwakening:get_total_spent()
  return self.total_spent
end

return DemonAwakening
