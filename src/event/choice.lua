local class = require('lib.middleclass')

---@class Choice
---@field text string
---@field effects table[]
---@field suspicion_delta number
local Choice = class('Choice')

---@param data {text: string, effects: table[], suspicion_delta: number}
function Choice:initialize(data)
  self.text = data.text
  self.effects = data.effects or {}
  self.suspicion_delta = data.suspicion_delta or 0
end

---@return string
function Choice:get_text()
  return self.text
end

---@return table[]
function Choice:get_effects()
  return self.effects
end

---@return number
function Choice:get_suspicion_delta()
  return self.suspicion_delta
end

---@param context {hero: table, suspicion_manager: table}
function Choice:apply(context)
  for _, effect in ipairs(self.effects) do
    if effect.type == "heal_hero" and context.hero then
      context.hero:heal(effect.amount)
    elseif effect.type == "damage_hero" and context.hero then
      context.hero:take_damage(effect.amount)
    elseif effect.type == "buff_attack" and context.hero then
      context.hero.attack = context.hero.attack + effect.amount
    end
  end
  if context.suspicion_manager then
    if self.suspicion_delta > 0 then
      context.suspicion_manager:add(self.suspicion_delta)
    elseif self.suspicion_delta < 0 then
      context.suspicion_manager:reduce(math.abs(self.suspicion_delta))
    end
  end
end

return Choice
