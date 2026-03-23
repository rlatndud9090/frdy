local Entity = require('src.combat.entity')
local ActionPattern = require('src.combat.action_pattern')
local PatternResolver = require('src.combat.pattern_resolver')
local reward_config = require('data.rewards.config')

---@class Hero : Entity
---@field level number
---@field experience number
---@field action_patterns ActionPattern[]
---@field cooldown_tracker table
---@field mental_load number
---@field current_turn number
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
  self.current_turn = 0

  -- Hero default patterns: fallback attack + low HP guard
  self.action_patterns = {
    ActionPattern:new({
      id = "hero_attack",
      name = "pattern.hero_attack.name",
      type = "attack",
      priority = 1,
      condition = "fallback",
      params = {damage_mult = 1.0},
    }),
    ActionPattern:new({
      id = "hero_guard",
      name = "pattern.hero_guard.name",
      type = "defend",
      priority = 20,
      condition = "hp_below",
      condition_params = {threshold = 0.6},
      cooldown = 2,
      params = {defense_bonus = 3},
    }),
  }
end

---@return number
function Hero:get_current_turn()
  return self.current_turn or 0
end

---@param turn number|nil
---@return nil
function Hero:set_current_turn(turn)
  self.current_turn = math.max(0, math.floor(turn or 0))
end

---@return nil
function Hero:reset_action_state()
  self.cooldown_tracker = {}
  self.current_turn = 0
end

---@param pattern_id string|nil
---@param turn number|nil
---@return nil
function Hero:mark_pattern_used(pattern_id, turn)
  if not pattern_id or pattern_id == '' then
    return
  end
  local current_turn = turn
  if current_turn == nil then
    current_turn = self.current_turn or 0
  end
  self.cooldown_tracker[pattern_id] = math.max(0, math.floor(current_turn))
end

---@return number
function Hero:get_mental_load()
  return self.mental_load
end

---@return number
function Hero:get_level()
  return self.level
end

---@return number
function Hero:get_experience()
  return self.experience
end

---@return number
function Hero:get_next_level_experience()
  local base = reward_config.hero_level and reward_config.hero_level.base_threshold or 100
  return base * self.level
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

---@param pattern_id string
---@return ActionPattern|nil
function Hero:get_action_pattern(pattern_id)
  for _, pattern in ipairs(self.action_patterns) do
    if pattern.id == pattern_id then
      return pattern
    end
  end
  return nil
end

---@param pattern_id string
---@return boolean
function Hero:has_action_pattern(pattern_id)
  return self:get_action_pattern(pattern_id) ~= nil
end

---@return number
function Hero:get_action_pattern_count()
  return #self.action_patterns
end

---@param protected_ids string[]|nil
---@return string[]
function Hero:get_removable_pattern_ids(protected_ids)
  local protected_lookup = {}
  for _, id in ipairs(protected_ids or {}) do
    protected_lookup[id] = true
  end

  local ids = {}
  for _, pattern in ipairs(self.action_patterns) do
    if not protected_lookup[pattern.id] then
      ids[#ids + 1] = pattern.id
    end
  end
  return ids
end

---@param pattern_data table
---@return boolean
function Hero:add_action_pattern(pattern_data)
  if not pattern_data or not pattern_data.id then
    return false
  end
  if self:has_action_pattern(pattern_data.id) then
    return false
  end

  local data = {}
  for k, v in pairs(pattern_data) do
    data[k] = v
  end
  local pattern = ActionPattern:new(data)
  pattern.reward_rank = 1
  pattern.max_reward_rank = (reward_config.pattern_upgrade and reward_config.pattern_upgrade.max_rank) or 5
  self.action_patterns[#self.action_patterns + 1] = pattern
  return true
end

---@param pattern_id string
---@return boolean
function Hero:remove_action_pattern(pattern_id)
  for i = #self.action_patterns, 1, -1 do
    if self.action_patterns[i].id == pattern_id then
      table.remove(self.action_patterns, i)
      return true
    end
  end
  return false
end

---@param pattern_id string
---@param upgrade_spec table|nil
---@return boolean
function Hero:upgrade_action_pattern(pattern_id, upgrade_spec)
  local pattern = self:get_action_pattern(pattern_id)
  if not pattern then
    return false
  end

  local spec = upgrade_spec or reward_config.pattern_upgrade or {}
  local max_rank = spec.max_rank or 5
  local rank = pattern.reward_rank or 1
  if rank >= max_rank then
    return false
  end

  pattern.reward_rank = rank + 1
  pattern.max_reward_rank = max_rank

  if pattern.type == "attack" then
    pattern.params.damage_mult = (pattern.params.damage_mult or 1.0) + (spec.attack_mult_delta or 0.15)
  elseif pattern.type == "defend" then
    pattern.params.defense_bonus = (pattern.params.defense_bonus or 0) + (spec.defense_bonus_delta or 1)
  elseif pattern.type == "heal" then
    pattern.params.amount = (pattern.params.amount or 0) + (spec.heal_amount_delta or 2)
  end

  return true
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
  context.current_turn = context.current_turn or self.current_turn or 0
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

---@class HeroLevelResult
---@field gained_levels number
---@field crossed_milestones number

---@param amount number
---@return HeroLevelResult
function Hero:add_experience(amount)
  local gained_levels = 0
  local crossed_milestones = 0
  local exp_gain = math.max(0, math.floor(amount or 0))
  self.experience = self.experience + exp_gain

  local base_threshold = reward_config.hero_level and reward_config.hero_level.base_threshold or 100
  local hp_per_level = reward_config.hero_level and reward_config.hero_level.hp_per_level or 5
  local attack_per_level = reward_config.hero_level and reward_config.hero_level.attack_per_level or 1
  local speed_per_level = reward_config.hero_level and reward_config.hero_level.speed_per_level or 0.5
  local milestone_interval = reward_config.hero_level and reward_config.hero_level.milestone_interval or 5

  local threshold = base_threshold * self.level
  while self.experience >= threshold do
    self.experience = self.experience - threshold
    self.level = self.level + 1
    gained_levels = gained_levels + 1

    self.max_hp = self.max_hp + hp_per_level
    self.attack = self.attack + attack_per_level
    self.speed = self.speed + speed_per_level
    self.hp = self.max_hp

    if self.level % milestone_interval == 0 then
      crossed_milestones = crossed_milestones + 1
    end

    threshold = base_threshold * self.level
  end

  return {
    gained_levels = gained_levels,
    crossed_milestones = crossed_milestones,
  }
end

---@param rewards {exp?: number, hp_bonus?: number, attack_bonus?: number}
---@return HeroLevelResult
function Hero:grow(rewards)
  rewards = rewards or {}
  local level_result = self:add_experience(rewards.exp or 0)
  self.max_hp = self.max_hp + (rewards.hp_bonus or 0)
  self.hp = math.min(self.max_hp, self.hp + (rewards.hp_bonus or 0))
  self.attack = self.attack + (rewards.attack_bonus or 0)
  return level_result
end

function Hero:snapshot()
  local snap = Entity.snapshot(self)
  snap.level = self.level
  snap.experience = self.experience
  snap.mental_load = self.mental_load
  snap.current_turn = self.current_turn
  snap.cooldown_tracker = {}
  for pattern_id, turn in pairs(self.cooldown_tracker or {}) do
    snap.cooldown_tracker[pattern_id] = turn
  end
  snap.action_patterns = {}
  for index, pattern in ipairs(self.action_patterns or {}) do
    snap.action_patterns[index] = pattern:snapshot()
  end
  return snap
end

---@return table
function Hero:persistent_snapshot()
  local patterns = {}
  for index, pattern in ipairs(self.action_patterns or {}) do
    patterns[index] = pattern:snapshot()
  end

  local cooldown_tracker = {}
  for pattern_id, turn in pairs(self.cooldown_tracker or {}) do
    cooldown_tracker[pattern_id] = turn
  end

  return {
    hp = self.hp,
    max_hp = self.max_hp,
    attack = self.attack,
    defense = self.defense,
    speed = self.speed,
    level = self.level,
    experience = self.experience,
    mental_load = self.mental_load,
    current_turn = self.current_turn,
    cooldown_tracker = cooldown_tracker,
    action_patterns = patterns,
  }
end

---@param snap table
function Hero:restore(snap)
  Entity.restore(self, snap)
  self.level = snap.level
  self.experience = snap.experience
  self.mental_load = snap.mental_load or 0
  self.current_turn = snap.current_turn or 0
  self.cooldown_tracker = {}
  for pattern_id, turn in pairs(snap.cooldown_tracker or {}) do
    self.cooldown_tracker[pattern_id] = turn
  end
  if type(snap.action_patterns) == 'table' then
    self.action_patterns = {}
    for index, pattern_snapshot in ipairs(snap.action_patterns) do
      self.action_patterns[index] = ActionPattern.from_snapshot(pattern_snapshot)
    end
  end
end

---@param snapshot table|nil
---@return nil
function Hero:restore_persistent_snapshot(snapshot)
  if type(snapshot) ~= 'table' then
    return
  end

  self.hp = snapshot.hp or self.hp
  self.max_hp = snapshot.max_hp or self.max_hp
  self.attack = snapshot.attack or self.attack
  self.defense = snapshot.defense or self.defense
  self.speed = snapshot.speed or self.speed
  self.level = snapshot.level or self.level
  self.experience = snapshot.experience or self.experience
  self.mental_load = snapshot.mental_load or 0
  self.current_turn = snapshot.current_turn or 0

  self.cooldown_tracker = {}
  for pattern_id, turn in pairs(snapshot.cooldown_tracker or {}) do
    self.cooldown_tracker[pattern_id] = turn
  end

  self.action_patterns = {}
  for index, pattern_snapshot in ipairs(snapshot.action_patterns or {}) do
    self.action_patterns[index] = ActionPattern.from_snapshot(pattern_snapshot)
  end
end

return Hero
