local class = require('lib.middleclass')

---@class Spell
---@field id string
---@field name string
---@field description string
---@field cost number
---@field suspicion_delta number
---@field effect SpellEffectObject
---@field timeline_type string "insert"|"manipulate_swap"|"manipulate_remove"|"manipulate_delay"|"manipulate_modify"|"global"
---@field new fun(self: Spell, data: table): Spell
local Spell = class('Spell')

--- Initialize a spell from a data table
---@param data table
function Spell:initialize(data)
  self.id = data.id
  self.name = data.name
  self.description = data.description
  self.cost = data.cost
  self.suspicion_delta = data.suspicion_delta
  self.effect = data.effect
  self.timeline_type = data.timeline_type or "insert"
end

---@return string
function Spell:get_id()
  return self.id
end

---@return string
function Spell:get_name()
  return self.name
end

---@return string
function Spell:get_description()
  return self.description
end

---@return number
function Spell:get_cost()
  return self.cost
end

---@return number
function Spell:get_suspicion_delta()
  return self.suspicion_delta
end

---@return SpellEffectObject
function Spell:get_effect()
  return self.effect
end

---@return string
function Spell:get_timeline_type()
  return self.timeline_type
end

--- Check if this spell can be played given current mana
---@param mana_manager ManaManager
---@return boolean
function Spell:can_play(mana_manager)
  return mana_manager:can_afford(self.cost)
end

--- Reserve mana for this spell (timeline placement)
---@param mana_manager ManaManager
---@return boolean
function Spell:reserve(mana_manager)
  return mana_manager:reserve(self.cost)
end

--- Unreserve mana for this spell (timeline removal)
---@param mana_manager ManaManager
function Spell:unreserve(mana_manager)
  mana_manager:unreserve(self.cost)
end

--- Execute spell effect (after confirmation, during EXECUTION phase)
---@param target any
---@param context {hero: any, enemies: any, suspicion_manager: SuspicionManager}
function Spell:execute(target, context)
  self.effect:apply(target, context)

  if context.suspicion_manager then
    if self.suspicion_delta > 0 then
      context.suspicion_manager:add(self.suspicion_delta)
    elseif self.suspicion_delta < 0 then
      context.suspicion_manager:reduce(math.abs(self.suspicion_delta))
    end
  end
end

--- Play this spell: spend mana + apply effect + suspicion (legacy compat)
---@param target any
---@param context {hero: any, enemies: any, mana_manager: ManaManager, suspicion_manager: SuspicionManager}
---@return boolean
function Spell:play(target, context)
  if not self:can_play(context.mana_manager) then
    return false
  end

  context.mana_manager:spend(self.cost)
  self:execute(target, context)
  return true
end

return Spell
