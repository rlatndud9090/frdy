local class = require('lib.middleclass')
local i18n = require('src.i18n.init')

---@class Choice
---@field text string
---@field effects table[]
local Choice = class('Choice')

---@param data {text: string, effects: table[]}
function Choice:initialize(data)
  self.text = data.text
  self.effects = data.effects or {}
end

---@return string
function Choice:get_text()
  return i18n.t(self.text)
end

---@return table[]
function Choice:get_effects()
  return self.effects
end

---@param context {hero: table}
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
end

return Choice
