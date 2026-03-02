local class = require('lib.middleclass')

---@class LegendaryItemDefinition
---@field id string
---@field name_key string
---@field desc_key string
---@field modifiers table|nil

---@class LegendaryInventory
---@field _owned_ids string[]
---@field _owned_lookup table<string, LegendaryItemDefinition>
---@field _reward_control_bonus number
local LegendaryInventory = class('LegendaryInventory')

function LegendaryInventory:initialize()
  self._owned_ids = {}
  self._owned_lookup = {}
  self._reward_control_bonus = 0
end

---@param item_def LegendaryItemDefinition
---@param context table
---@param sign number
---@return nil
function LegendaryInventory:_apply_modifiers(item_def, context, sign)
  local modifiers = item_def.modifiers or {}
  local hero = context and context.hero or nil
  local reward_manager = context and context.reward_manager or nil

  if hero then
    local hp_delta = (modifiers.hero_max_hp or 0) * sign
    if hp_delta ~= 0 then
      hero.max_hp = math.max(1, hero.max_hp + hp_delta)
      if hp_delta > 0 then
        hero.hp = math.min(hero.max_hp, hero.hp + hp_delta)
      else
        hero.hp = math.min(hero.max_hp, hero.hp)
      end
    end

    local atk_delta = (modifiers.hero_attack or 0) * sign
    if atk_delta ~= 0 then
      hero.attack = math.max(0, hero.attack + atk_delta)
    end

    local speed_delta = (modifiers.hero_speed or 0) * sign
    if speed_delta ~= 0 then
      hero.speed = math.max(0, hero.speed + speed_delta)
    end
  end

  local stage_delta = (modifiers.reward_control_max_stage_bonus or 0) * sign
  if stage_delta ~= 0 then
    self._reward_control_bonus = self._reward_control_bonus + stage_delta
    if reward_manager and reward_manager.adjust_reward_control_bonus then
      reward_manager:adjust_reward_control_bonus(stage_delta)
    end
  end
end

---@param item_id string
---@return boolean
function LegendaryInventory:has_item(item_id)
  return self._owned_lookup[item_id] ~= nil
end

---@return string[]
function LegendaryInventory:get_owned_ids()
  local copied = {}
  for i = 1, #self._owned_ids do
    copied[i] = self._owned_ids[i]
  end
  return copied
end

---@return number
function LegendaryInventory:get_count()
  return #self._owned_ids
end

---@return number
function LegendaryInventory:get_reward_control_bonus()
  return self._reward_control_bonus
end

---@param item_def LegendaryItemDefinition
---@param context table
---@return boolean
function LegendaryInventory:add_item(item_def, context)
  if not item_def or not item_def.id then
    return false
  end
  if self:has_item(item_def.id) then
    return false
  end

  self._owned_lookup[item_def.id] = item_def
  self._owned_ids[#self._owned_ids + 1] = item_def.id
  self:_apply_modifiers(item_def, context or {}, 1)
  return true
end

---@param item_id string
---@param context table
---@return LegendaryItemDefinition|nil
function LegendaryInventory:remove_by_id(item_id, context)
  local item_def = self._owned_lookup[item_id]
  if not item_def then
    return nil
  end

  self:_apply_modifiers(item_def, context or {}, -1)
  self._owned_lookup[item_id] = nil
  for i = #self._owned_ids, 1, -1 do
    if self._owned_ids[i] == item_id then
      table.remove(self._owned_ids, i)
      break
    end
  end

  return item_def
end

---@param context table
---@return LegendaryItemDefinition|nil
function LegendaryInventory:remove_random(context)
  if #self._owned_ids == 0 then
    return nil
  end

  local index = math.random(#self._owned_ids)
  local item_id = self._owned_ids[index]
  return self:remove_by_id(item_id, context)
end

return LegendaryInventory
