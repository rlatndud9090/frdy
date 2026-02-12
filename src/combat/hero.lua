local Entity = require('src.combat.entity')
local ActionPattern = require('src.combat.action_pattern')
local PatternResolver = require('src.combat.pattern_resolver')

---@class Hero : Entity
---@field level number
---@field experience number
---@field action_patterns ActionPattern[]
---@field cooldown_tracker table
local Hero = Entity:subclass('Hero')

---@param stats {hp: number, attack: number, defense: number}
function Hero:initialize(stats)
  Entity.initialize(self, "entity.hero", stats)
  self.level = 1
  self.experience = 0
  self.cooldown_tracker = {}

  -- Hero default patterns: always attack
  self.action_patterns = {
    ActionPattern:new({
      id = "hero_attack",
      name = "attack",
      type = "attack",
      priority = 1,
      condition = "always",
      params = {damage_mult = 1.0},
    }),
  }
end

--- Choose action using PatternResolver
---@param context? table
---@return ActionPattern|nil
function Hero:choose_action(context)
  context = context or {}
  context.actor = self
  context.cooldown_tracker = self.cooldown_tracker
  return PatternResolver.resolve(self.action_patterns, context)
end

---@return {type: string, value: number, description: string}|nil
function Hero:get_intent()
  local pattern = self:choose_action()
  if pattern then
    return pattern:get_preview(self)
  end
  return nil
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
