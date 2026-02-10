local class = require('lib.middleclass')

---@class Card
---@field id string
---@field name string
---@field description string
---@field cost number
---@field suspicion_delta number
---@field effect CardEffectObject
---@field new fun(self: Card, data: table): Card
local Card = class('Card')

--- Initialize a card from a data table
---@param data {id: string, name: string, description: string, cost: number, suspicion_delta: number, effect: CardEffectObject}
function Card:initialize(data)
  self.id = data.id
  self.name = data.name
  self.description = data.description
  self.cost = data.cost
  self.suspicion_delta = data.suspicion_delta
  self.effect = data.effect
end

---@return string
function Card:get_id()
  return self.id
end

---@return string
function Card:get_name()
  return self.name
end

---@return string
function Card:get_description()
  return self.description
end

---@return number
function Card:get_cost()
  return self.cost
end

---@return number
function Card:get_suspicion_delta()
  return self.suspicion_delta
end

---@return CardEffectObject
function Card:get_effect()
  return self.effect
end

--- Check if this card can be played given current mana
---@param mana_manager ManaManager
---@return boolean
function Card:can_play(mana_manager)
  return mana_manager:can_afford(self.cost)
end

--- Play this card: spend mana, apply effect, adjust suspicion
---@param target any
---@param context {hero: any, enemies: any, mana_manager: ManaManager, suspicion_manager: SuspicionManager}
---@return boolean
function Card:play(target, context)
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

return Card
