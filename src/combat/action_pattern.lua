local class = require('lib.middleclass')
local i18n = require('src.i18n.init')

---@class ActionPattern
---@field id string
---@field name string
---@field type string "attack"|"defend"|"heal"|"buff"|"debuff"
---@field priority number
---@field condition string "always"|"hp_below"|"hp_above"|"target_hp_below"|"enemy_count_above"|"fallback"
---@field condition_params table
---@field cooldown number
---@field params table
local ActionPattern = class('ActionPattern')

---@param data table
function ActionPattern:initialize(data)
  self.id = data.id or "auto"
  self.name = data.name or data.type
  self.type = data.type
  self.priority = data.priority or 0
  self.condition = data.condition or "always"
  self.condition_params = data.condition_params or {}
  self.cooldown = data.cooldown or 0
  self.params = data.params or {}
end

--- Check if this pattern can be used in given context
---@param context {actor: Entity, target: Entity, enemies: Entity[], cooldown_tracker: table}
---@return boolean
function ActionPattern:can_use(context)
  -- Check cooldown
  if self.cooldown > 0 and context.cooldown_tracker then
    local last_used = context.cooldown_tracker[self.id] or -999
    local current_turn = context.current_turn or 0
    if (current_turn - last_used) < self.cooldown then
      return false
    end
  end

  -- Check condition
  if self.condition == "always" then
    return true
  elseif self.condition == "fallback" then
    return true -- lowest priority, always usable
  elseif self.condition == "hp_below" then
    local threshold = self.condition_params.threshold or 0.5
    return context.actor and (context.actor:get_hp() / context.actor:get_max_hp()) < threshold
  elseif self.condition == "hp_above" then
    local threshold = self.condition_params.threshold or 0.5
    return context.actor and (context.actor:get_hp() / context.actor:get_max_hp()) > threshold
  elseif self.condition == "target_hp_below" then
    local threshold = self.condition_params.threshold or 0.3
    return context.target and (context.target:get_hp() / context.target:get_max_hp()) < threshold
  elseif self.condition == "enemy_count_above" then
    local count = self.condition_params.count or 1
    return context.enemies and #context.enemies > count
  end

  return false
end

--- Execute this pattern
---@param actor Entity
---@param target Entity
function ActionPattern:execute(actor, target)
  if self.type == "attack" then
    local mult = self.params.damage_mult or 1.0
    local damage = math.floor(actor:get_attack() * mult)
    target:take_damage(damage)
  elseif self.type == "defend" then
    local bonus = self.params.defense_bonus or 0
    actor.defense = actor.defense + bonus
  elseif self.type == "heal" then
    local amount = self.params.amount or 0
    actor:heal(amount)
  end
end

--- Get preview description for this pattern
---@param actor Entity
---@return {type: string, value: number, description: string}
function ActionPattern:get_preview(actor)
  if self.type == "attack" then
    local mult = self.params.damage_mult or 1.0
    local damage = math.floor(actor:get_attack() * mult)
    return {
      type = "attack",
      value = damage,
      description = i18n.t("intent.attack") .. " " .. damage,
    }
  elseif self.type == "defend" then
    local bonus = self.params.defense_bonus or 0
    return {
      type = "defend",
      value = bonus,
      description = i18n.t("intent.defense") .. " +" .. bonus,
    }
  else
    return {
      type = self.type,
      value = 0,
      description = self.name,
    }
  end
end

--- Create ActionPattern from legacy round-robin data
---@param data {type: string, damage_mult?: number, defense_bonus?: number}
---@param index number
---@return ActionPattern
function ActionPattern.from_legacy(data, index)
  return ActionPattern:new({
    id = "auto_" .. index,
    name = data.type,
    type = data.type,
    priority = index,
    condition = "always",
    params = {
      damage_mult = data.damage_mult,
      defense_bonus = data.defense_bonus,
    },
  })
end

return ActionPattern
