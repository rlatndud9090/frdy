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

---@param context {hero: Hero|nil, reward_manager?: RewardManager}
function Choice:apply(context)
  for _, effect in ipairs(self.effects) do
    if effect.type == "heal_hero" and context.hero then
      context.hero:heal(effect.amount)
    elseif effect.type == "damage_hero" and context.hero then
      context.hero:take_damage(effect.amount)
    elseif effect.type == "buff_attack" and context.hero then
      context.hero.attack = context.hero.attack + effect.amount
    elseif effect.type == "grant_hero_exp" and context.reward_manager then
      context.reward_manager:grant_hero_experience(effect.amount or 0, "event")
    elseif effect.type == "grant_reward_offer" and context.reward_manager then
      context.reward_manager:enqueue_offer(effect.category, "event", effect.count or 1)
    elseif effect.type == "remove_owned_reward" and context.reward_manager then
      context.reward_manager:remove_owned_reward(
        effect.category,
        effect.count or 1,
        effect.mode,
        effect.id
      )
    end
  end
end

return Choice
