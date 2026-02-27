local Entity = require('src.combat.entity')
local ActionPattern = require('src.combat.action_pattern')
local PatternResolver = require('src.combat.pattern_resolver')

---@class Hero : Entity
---@field level number
---@field experience number
---@field action_patterns ActionPattern[]
---@field cooldown_tracker table
---@field mental_load number
local Hero = Entity:subclass('Hero')

local MAX_MENTAL_STAGE = 5
local MAX_MENTAL_LOAD = 5

---@param stats {hp: number, attack: number, defense: number, speed?: number}
function Hero:initialize(stats)
  Entity.initialize(self, "entity.hero", stats)
  self.level = 1
  self.experience = 0
  self.cooldown_tracker = {}
  self.mental_load = 0

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

---@return number
function Hero:get_mental_load()
  return self.mental_load
end

---@return number
function Hero:get_max_mental_stage()
  return MAX_MENTAL_STAGE
end

---@return number
function Hero:get_mental_stage()
  local stage = math.floor(self.mental_load) + 1
  if stage > MAX_MENTAL_STAGE then
    return MAX_MENTAL_STAGE
  end
  if stage < 1 then
    return 1
  end
  return stage
end

---@param max_stage number
---@return boolean
function Hero:can_be_controlled(max_stage)
  return self:get_mental_stage() <= max_stage
end

---@param amount number
---@return number
function Hero:increase_mental_load(amount)
  self.mental_load = math.max(0, math.min(MAX_MENTAL_LOAD, self.mental_load + amount))
  return self.mental_load
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
  snap.mental_load = self.mental_load
  return snap
end

---@param snap table
function Hero:restore(snap)
  Entity.restore(self, snap)
  self.level = snap.level
  self.experience = snap.experience
  self.mental_load = snap.mental_load or 0
end

return Hero
