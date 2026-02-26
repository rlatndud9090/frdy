local Entity = require('src.combat.entity')
local PatternResolver = require('src.combat.pattern_resolver')

---@class Enemy : Entity
---@field action_patterns ActionPattern[]
---@field legacy_patterns table[]
---@field current_pattern_index number
---@field cooldown_tracker table
---@field intent table|nil
local Enemy = Entity:subclass('Enemy')

---@param name string
---@param stats {hp: number, attack: number, defense: number, speed?: number}
---@param action_patterns table[]
function Enemy:initialize(name, stats, action_patterns)
  Entity.initialize(self, name, stats)
  self.legacy_patterns = action_patterns or {{type = "attack", damage_mult = 1.0}}
  self.action_patterns = PatternResolver.from_legacy_list(self.legacy_patterns)
  self.current_pattern_index = 1
  self.cooldown_tracker = {}
  self.intent = nil
end

--- Choose action using round-robin (legacy compat) with PatternResolver
---@param context? table
---@return ActionPattern|nil
function Enemy:choose_action(context)
  if #self.action_patterns == 0 then
    return nil
  end
  return self.action_patterns[self.current_pattern_index]
end

--- Consume current action cursor after an action is committed
---@return nil
function Enemy:consume_action()
  if #self.action_patterns == 0 then
    return
  end
  self.current_pattern_index = self.current_pattern_index % #self.action_patterns + 1
end

---@return table|nil
function Enemy:get_intent()
  return self.intent
end

--- Prepare next action preview
function Enemy:prepare_intent()
  local pattern = self.action_patterns[self.current_pattern_index]
  if pattern then
    self.intent = pattern:get_preview(self)
  end
end

function Enemy:snapshot()
  local snap = Entity.snapshot(self)
  snap.current_pattern_index = self.current_pattern_index
  snap.intent = self.intent
  return snap
end

function Enemy:restore(snap)
  Entity.restore(self, snap)
  self.current_pattern_index = snap.current_pattern_index
  self.intent = snap.intent
end

return Enemy
