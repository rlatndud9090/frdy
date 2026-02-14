local class = require('lib.middleclass')

---@class TimelineManagerIntervention
---@field kind string
---@field index number
---@field dest_index? number
---@field spell Spell
---@field delay_amount? number
---@field modify_delta? number
---@field global_attack_delta? number
---@field actor? Entity
---@field target? Entity
---@field target_enemy_index? number
---@field state_snapshot? PredictionStateSnapshot

---@class TimelineManager
---@field timeline PredictedAction[]
---@field interventions TimelineManagerIntervention[]
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

--- Regenerate the timeline from current state and interventions
function TimelineManager:regenerate()
  if not self.hero or not self.enemies then return end
  if #self.interventions == 0 then
    self.timeline = self.prediction_engine:generate_timeline(self.hero, self.enemies)
  else
    self.timeline = self.prediction_engine:recalculate_with(self.hero, self.enemies, self.interventions)
  end
end

--- Insert a spell intervention at a specific index
---@param index number
---@param spell Spell
---@param actor Entity
---@param target Entity
---@param target_enemy_index? number
---@param state_snapshot? PredictionStateSnapshot
function TimelineManager:insert_at(index, spell, actor, target, target_enemy_index, state_snapshot)
  local snapshot = state_snapshot
  if not snapshot and index <= 1 then
    snapshot = self:_build_initial_snapshot()
  end

  table.insert(self.interventions, {
    kind = 'insert',
    index = index,
    spell = spell,
    actor = actor,
    target = target,
    target_enemy_index = target_enemy_index,
    state_snapshot = snapshot,
  })
  self:regenerate()
end


---@return PredictionStateSnapshot
function TimelineManager:_build_initial_snapshot()
  local snapshot = {
    hero_hp = self.hero and self.hero:get_hp() or 0,
    hero_max_hp = self.hero and self.hero:get_max_hp() or 0,
    hero_defense = self.hero and self.hero:get_defense() or 0,
    enemies = {},
  }

  if not self.enemies then
    return snapshot
  end

  for i, enemy in ipairs(self.enemies) do
    if enemy:is_alive() then
      table.insert(snapshot.enemies, {
        id = i,
        name = enemy:get_name(),
        hp = enemy:get_hp(),
        max_hp = enemy:get_max_hp(),
        defense = enemy:get_defense(),
        alive = enemy:is_alive(),
      })
    end
  end

  return snapshot
end

--- Swap two positions in the timeline
---@param a number
---@param b number
---@param spell Spell
function TimelineManager:swap(a, b, spell)
  table.insert(self.interventions, {
    kind = 'swap',
    index = a,
    dest_index = b,
    spell = spell,
  })
  self:regenerate()
end

--- Remove action at index
---@param index number
---@param spell Spell
function TimelineManager:remove_at(index, spell)
  table.insert(self.interventions, {
    kind = 'remove',
    index = index,
    spell = spell,
  })
  self:regenerate()
end

--- Delay action by amount
---@param index number
---@param amount number
---@param spell Spell
function TimelineManager:delay_at(index, amount, spell)
  table.insert(self.interventions, {
    kind = 'delay',
    index = index,
    delay_amount = amount,
    spell = spell,
  })
  self:regenerate()
end

--- Modify action value at index
---@param index number
---@param spell Spell
function TimelineManager:modify_at(index, spell)
  local effect = spell:get_effect()
  table.insert(self.interventions, {
    kind = 'modify',
    index = index,
    modify_delta = effect and effect.amount or 0,
    spell = spell,
  })
  self:regenerate()
end

--- Apply a global spell that affects the timeline
---@param spell Spell
function TimelineManager:apply_global(spell)
  local effect = spell:get_effect()
  table.insert(self.interventions, {
    kind = 'global',
    index = 0,
    global_attack_delta = effect and effect.amount or 0,
    spell = spell,
  })
  self:regenerate()
end

--- Confirm all interventions
function TimelineManager:confirm()
  self.interventions = {}
end

--- Reset: remove all interventions and regenerate
---@return Spell[]
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

---@return PredictedAction[]
function TimelineManager:get_timeline()
  return self.timeline
end

---@return number
function TimelineManager:get_count()
  return #self.timeline
end

---@param index number
---@return PredictedAction|nil
function TimelineManager:get_action(index)
  return self.timeline[index]
end

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

---@return boolean
function TimelineManager:has_interventions()
  return #self.interventions > 0
end

---@return TimelineManagerIntervention[]
function TimelineManager:get_interventions()
  return self.interventions
end

return TimelineManager
