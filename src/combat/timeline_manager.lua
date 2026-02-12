local class = require('lib.middleclass')

---@class TimelineManager
---@field timeline PredictedAction[]
---@field interventions table[] {index: number, spell: Spell}
---@field prediction_engine PredictionEngine
---@field hero Hero
---@field enemies Enemy[]
local TimelineManager = class('TimelineManager')

---@param prediction_engine PredictionEngine
function TimelineManager:initialize(prediction_engine)
  self.prediction_engine = prediction_engine
  self.timeline = {}
  self.interventions = {}
  self.hero = nil
  self.enemies = nil
end

--- Set combat participants and generate initial timeline
---@param hero Hero
---@param enemies Enemy[]
function TimelineManager:setup(hero, enemies)
  self.hero = hero
  self.enemies = enemies
  self.interventions = {}
  self:regenerate()
end

--- Regenerate the timeline from current state
function TimelineManager:regenerate()
  if not self.hero or not self.enemies then return end
  self.timeline = self.prediction_engine:generate_timeline(self.hero, self.enemies)
end

--- Insert a spell intervention at a specific index
---@param index number Position in timeline
---@param spell Spell
---@param predicted_action PredictedAction
function TimelineManager:insert_at(index, spell, predicted_action)
  index = math.max(1, math.min(index, #self.timeline + 1))
  table.insert(self.timeline, index, predicted_action)
  table.insert(self.interventions, {index = index, spell = spell})
end

--- Swap two positions in the timeline
---@param a number
---@param b number
function TimelineManager:swap(a, b)
  if a >= 1 and a <= #self.timeline and b >= 1 and b <= #self.timeline then
    self.timeline[a], self.timeline[b] = self.timeline[b], self.timeline[a]
  end
end

--- Remove action at index
---@param index number
---@return PredictedAction|nil removed action
function TimelineManager:remove_at(index)
  if index >= 1 and index <= #self.timeline then
    return table.remove(self.timeline, index)
  end
  return nil
end

--- Modify action at index with a spell effect
---@param index number
---@param spell Spell
function TimelineManager:modify_at(index, spell)
  if index >= 1 and index <= #self.timeline then
    local action = self.timeline[index]
    local effect = spell:get_effect()
    if effect and action then
      -- Modify the action's value based on spell effect
      if effect.type == "damage" then
        action.value = math.max(0, action.value - effect.amount)
      end
    end
    table.insert(self.interventions, {index = index, spell = spell, modify = true})
  end
end

--- Apply a global spell that affects the entire timeline
---@param spell Spell
function TimelineManager:apply_global(spell)
  table.insert(self.interventions, {index = 0, spell = spell, global = true})
end

--- Confirm all interventions
function TimelineManager:confirm()
  -- Interventions are already applied to the timeline
  -- Just clear the intervention tracking
  self.interventions = {}
end

--- Reset: remove all interventions and regenerate
---@return Spell[] released spells for mana refund
function TimelineManager:reset()
  local released = {}
  for _, intervention in ipairs(self.interventions) do
    table.insert(released, intervention.spell)
  end
  self.interventions = {}
  self:regenerate()
  return released
end

--- Get the current timeline
---@return PredictedAction[]
function TimelineManager:get_timeline()
  return self.timeline
end

--- Get number of actions in timeline
---@return number
function TimelineManager:get_count()
  return #self.timeline
end

--- Get action at index
---@param index number
---@return PredictedAction|nil
function TimelineManager:get_action(index)
  return self.timeline[index]
end

--- Get total suspicion preview from all interventions
---@return number
function TimelineManager:get_total_suspicion_preview()
  local total = 0
  for _, intervention in ipairs(self.interventions) do
    if intervention.spell then
      total = total + (intervention.spell:get_suspicion_delta() or 0)
    end
  end
  return total
end

--- Check if there are any interventions
---@return boolean
function TimelineManager:has_interventions()
  return #self.interventions > 0
end

--- Get all interventions
---@return table[]
function TimelineManager:get_interventions()
  return self.interventions
end

return TimelineManager
