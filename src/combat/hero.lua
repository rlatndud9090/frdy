local Entity = require('src.combat.entity')
local i18n = require('src.i18n.init')

---@class Hero : Entity
---@field level number
---@field experience number
local Hero = Entity:subclass('Hero')

---@param stats {hp: number, attack: number, defense: number}
function Hero:initialize(stats)
  Entity.initialize(self, "entity.hero", stats)
  self.level = 1
  self.experience = 0
end

---@return string
function Hero:get_action_pattern()
  return "attack"
end

---@return {type: string, damage: number, description: string}
function Hero:get_intent()
  return {
    type = "attack",
    damage = self.attack,
    description = i18n.t("intent.attack"),
  }
end

---@param rewards {exp: number, hp_bonus: number, attack_bonus: number}
function Hero:grow(rewards)
  self.experience = self.experience + (rewards.exp or 0)
  self.max_hp = self.max_hp + (rewards.hp_bonus or 0)
  self.hp = math.min(self.max_hp, self.hp + (rewards.hp_bonus or 0))
  self.attack = self.attack + (rewards.attack_bonus or 0)

  local threshold = 100 * self.level
  while self.experience >= threshold do
    self.experience = self.experience - threshold
    self.level = self.level + 1
    self.max_hp = self.max_hp + 5
    self.hp = self.max_hp
    self.attack = self.attack + 1
    threshold = 100 * self.level
  end
end

function Hero:snapshot()
  local snap = Entity.snapshot(self)
  snap.level = self.level
  snap.experience = self.experience
  return snap
end

function Hero:restore(snap)
  Entity.restore(self, snap)
  self.level = snap.level
  self.experience = snap.experience
end

return Hero
