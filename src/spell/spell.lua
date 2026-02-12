local class = require('lib.middleclass')

---@class Spell
---@field id string
---@field name string
---@field description string
---@field cost number
---@field suspicion_delta number
---@field effect SpellEffectObject
---@field new fun(self: Spell, data: table): Spell
local Spell = class('Spell')

--- Initialize a spell from a data table
---@param data {id: string, name: string, description: string, cost: number, suspicion_delta: number, effect: SpellEffectObject}
function Spell:initialize(data)
  self.id = data.id
  self.name = data.name
  self.description = data.description
  self.cost = data.cost
  self.suspicion_delta = data.suspicion_delta
  self.effect = data.effect
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

--- Check if this spell can be played given current mana
---@param mana_manager ManaManager
---@return boolean
function Spell:can_play(mana_manager)
  return mana_manager:can_afford(self.cost)
end

--- Play this spell: spend mana, apply effect, adjust suspicion
---@param target any
---@param context {hero: any, enemies: any, mana_manager: ManaManager, suspicion_manager: SuspicionManager}
---@return boolean
function Spell:play(target, context)
  if not self:can_play(context.mana_manager) then
    return false
  end

  context.mana_manager:spend(self.cost)
  self.effect:apply(target, context)

  if self.suspicion_delta > 0 then
    context.suspicion_manager:add(self.suspicion_delta)
  elseif self.suspicion_delta < 0 then
    context.suspicion_manager:reduce(math.abs(self.suspicion_delta))
  end

  return true
end

return Spell
