local class = require('lib.middleclass')

---@class TimelineManager
---@field timeline PredictedAction[]
---@field interventions table[]
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

---@param index number
---@return number
function TimelineManager:_normalize_index(index)
  local count = #self.timeline
  if count == 0 then
    return 1
  end
  return math.max(1, math.min(index, count))
end

---@param intervention table
---@return nil
function TimelineManager:_record_intervention(intervention)
  self.interventions[#self.interventions + 1] = intervention
end

---@param start_index number
---@param force_preserve_actor_slots? boolean
---@return nil
function TimelineManager:_recalculate_from(start_index, force_preserve_actor_slots)
  if not self.hero or not self.enemies then
    return
  end
  if #self.timeline == 0 then
    return
  end

  local clamped_start = self:_normalize_index(start_index)
  local preserve_actor_slots = force_preserve_actor_slots
  if preserve_actor_slots == nil then
    preserve_actor_slots = self:_has_actor_slot_intervention_from(clamped_start)
  end
  self.timeline = self.prediction_engine:recalculate_with(
    self.hero,
    self.enemies,
    self.timeline,
    clamped_start,
    {preserve_actor_slots = preserve_actor_slots}
  )
  self:_reapply_value_interventions_from(clamped_start)
end

---@param start_index number
---@return boolean
function TimelineManager:_has_actor_slot_intervention_from(start_index)
  for _, intervention in ipairs(self.interventions) do
    local itype = intervention.type
    local idx = intervention.index or 1
    if idx >= start_index and (itype == "swap" or itype == "delay" or itype == "remove") then
      return true
    end
  end
  return false
end

---@param start_index number
---@return nil
function TimelineManager:_reapply_value_interventions_from(start_index)
  for _, intervention in ipairs(self.interventions) do
    if intervention.type == "global" then
      self:_apply_global_delta(start_index, intervention.amount or 0)
    elseif intervention.type == "modify" then
      if intervention.index and intervention.index >= start_index then
        self:_apply_action_delta(intervention.index, intervention.amount or 0)
      end
    end
  end
end

---@param index number
---@param delta number
---@return nil
function TimelineManager:_apply_action_delta(index, delta)
  local action = self.timeline[index]
  if not action then
    return
  end
  action.value = math.max(0, (action.value or 0) + delta)
end

---@param start_index number
---@param delta number
---@return nil
function TimelineManager:_apply_global_delta(start_index, delta)
  if delta == 0 then
    return
  end

  for idx = start_index, #self.timeline do
    local action = self.timeline[idx]
    if action and action:get_source_type() == "hero" and action:get_action_type() == "attack" then
      action.value = math.max(0, (action.value or 0) + delta)
    end
  end
end

--- Insert a spell intervention at a specific index
---@param index number Position in timeline
---@param spell Spell
---@param predicted_action PredictedAction
function TimelineManager:insert_at(index, spell, predicted_action)
  index = math.max(1, math.min(index, #self.timeline + 1))
  table.insert(self.timeline, index, predicted_action)
  self:_record_intervention({
    type = "insert",
    index = index,
    spell = spell,
  })
  self:_recalculate_from(index, false)
end

--- Swap two positions in the timeline
---@param a number
---@param b number
---@param spell? Spell
function TimelineManager:swap(a, b, spell)
  if a >= 1 and a <= #self.timeline and b >= 1 and b <= #self.timeline then
    self.timeline[a], self.timeline[b] = self.timeline[b], self.timeline[a]
    self:_record_intervention({
      type = "swap",
      index = math.min(a, b),
      a = a,
      b = b,
      spell = spell,
    })
    self:_recalculate_from(math.min(a, b), true)
  end
end

--- Remove action at index
---@param index number
---@param spell? Spell
---@return PredictedAction|nil removed action
function TimelineManager:remove_at(index, spell)
  if index >= 1 and index <= #self.timeline then
    local removed = table.remove(self.timeline, index)
    self:_record_intervention({
      type = "remove",
      index = index,
      spell = spell,
    })
    self:_recalculate_from(index, true)
    return removed
  end
  return nil
end

--- Delay action by swapping it to the right N times.
---@param index number
---@param positions number
---@param spell Spell
---@return nil
function TimelineManager:delay_at(index, positions, spell)
  if index < 1 or index > #self.timeline then
    return
  end

  local from = index
  local target = index
  local steps = math.max(1, positions or 1)
  for _ = 1, steps do
    if target < #self.timeline then
      self.timeline[target], self.timeline[target + 1] = self.timeline[target + 1], self.timeline[target]
      target = target + 1
    end
  end

  self:_record_intervention({
    type = "delay",
    index = from,
    to_index = target,
    amount = steps,
    spell = spell,
  })
  self:_recalculate_from(math.min(from, target), true)
end

--- Modify action at index with a spell effect
---@param index number
---@param spell Spell
function TimelineManager:modify_at(index, spell)
  if index >= 1 and index <= #self.timeline then
    local effect = spell:get_effect()
    local delta = (effect and effect.amount) or 0
    self:_record_intervention({
      type = "modify",
      index = index,
      amount = delta,
      spell = spell,
    })
    self:_recalculate_from(index)
  end
end

--- Apply a global spell that affects the entire timeline
---@param spell Spell
function TimelineManager:apply_global(spell)
  local effect = spell:get_effect()
  local delta = (effect and effect.amount) or 0
  self:_record_intervention({
    type = "global",
    index = 1,
    amount = delta,
    spell = spell,
  })
  self:_recalculate_from(1)
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
    if intervention.spell then
      table.insert(released, intervention.spell)
    end
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
