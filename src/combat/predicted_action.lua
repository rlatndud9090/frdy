local class = require('lib.middleclass')

---@class PredictedAction
---@field actor Entity
---@field pattern ActionPattern
---@field action_type string "attack"|"defend"|"heal"|"spell"
---@field target Entity|table|nil
---@field value number
---@field source_type string "hero"|"enemy"|"spell"
---@field spell Spell|nil
---@field description string
---@field state_snapshot table|nil
---@field slot_token number|nil
local PredictedAction = class('PredictedAction')

---@param data table
function PredictedAction:initialize(data)
  self.actor = data.actor
  self.pattern = data.pattern
  self.action_type = data.action_type or (data.pattern and data.pattern.type) or "attack"
  self.target = data.target
  self.value = data.value or 0
  self.source_type = data.source_type or "enemy"
  self.spell = data.spell
  self.description = data.description or ""
  self.state_snapshot = data.state_snapshot
  self.slot_token = data.slot_token
end

---@return string
function PredictedAction:get_description()
  return self.description
end

---@return string
function PredictedAction:get_source_type()
  return self.source_type
end

---@return string
function PredictedAction:get_action_type()
  return self.action_type
end

---@return number
function PredictedAction:get_value()
  return self.value
end

---@return boolean
function PredictedAction:is_intervention()
  return self.source_type == "spell"
end

return PredictedAction
