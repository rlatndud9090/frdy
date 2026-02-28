local class = require('lib.middleclass')
local i18n = require('src.i18n.init')

---@class Spell
---@field id string
---@field name string
---@field description string
---@field desc_key string|nil
---@field cost number
---@field suspicion_delta number
---@field suspicion_abs number
---@field target_mode string "char_single"|"char_faction"|"char_all"|"action_next_n"|"action_next_all"
---@field target_n number|nil
---@field keywords string[]
---@field effect SpellEffectObject
---@field timeline_type string "insert"
---@field new fun(self: Spell, data: table): Spell
local Spell = class('Spell')

---@param effect SpellEffectObject|nil
---@return string
local function infer_target_mode(effect)
  if not effect then
    return "char_single"
  end

  if effect.type == "action_delta" or effect.type == "action_block" then
    return "action_next_n"
  end

  return "char_single"
end

---@param target_mode string
---@param effect SpellEffectObject|nil
---@return string[]
local function infer_keywords(target_mode, effect)
  local list = {}

  local function add(key)
    for _, existing in ipairs(list) do
      if existing == key then
        return
      end
    end
    list[#list + 1] = key
  end

  if target_mode == "char_single" then
    add("char_single")
  elseif target_mode == "char_faction" then
    add("char_faction")
  elseif target_mode == "char_all" then
    add("char_all")
  elseif target_mode == "action_next_n" then
    add("next_n")
  elseif target_mode == "action_next_all" then
    add("next_all")
  end

  if effect then
    if effect.type == "action_block" then
      add("block")
    elseif effect.type == "buff_speed" or effect.type == "debuff_speed" then
      add("speed")
    elseif effect.type == "action_delta" then
      add("action_value")
    end
  end

  return list
end

--- Initialize a spell from a data table
---@param data table
function Spell:initialize(data)
  self.id = data.id
  self.name = data.name
  self.description = data.description or ""
  self.desc_key = data.desc_key
  self.cost = data.cost
  self.suspicion_delta = data.suspicion_delta or data.suspicion_abs or 0
  self.suspicion_abs = math.abs(data.suspicion_abs or self.suspicion_delta or 0)
  self.effect = data.effect
  self.timeline_type = "insert"

  local raw_mode = data.target_mode
  if not raw_mode then
    if data.target_scope == "all" then
      raw_mode = "char_all"
    elseif data.target_scope == "faction" then
      raw_mode = "char_faction"
    elseif data.target_scope == "single" then
      raw_mode = "char_single"
    end
  end
  if raw_mode == "hero" or raw_mode == "enemy" or raw_mode == "any" then
    raw_mode = "char_single"
  end
  self.target_mode = raw_mode or infer_target_mode(self.effect)

  if data.target_n then
    self.target_n = math.max(1, math.floor(data.target_n))
  elseif self.target_mode == "action_next_n" then
    self.target_n = 1
  else
    self.target_n = nil
  end

  if data.keywords then
    self.keywords = {}
    for _, key in ipairs(data.keywords) do
      self.keywords[#self.keywords + 1] = key
    end
  else
    self.keywords = infer_keywords(self.target_mode, self.effect)
  end
end

---@return string
function Spell:get_id()
  return self.id
end

---@return string
function Spell:get_name()
  return self.name
end

---@return string
function Spell:get_description()
  if self.desc_key then
    return i18n.t(self.desc_key, self:get_description_params())
  end
  return self.description
end

---@return number
function Spell:get_cost()
  return self.cost
end

---@return number
function Spell:get_suspicion_delta()
  return self.suspicion_delta
end

---@return number
function Spell:get_suspicion_abs()
  return self.suspicion_abs
end

---@return string
function Spell:get_target_mode()
  return self.target_mode
end

---@return number|nil
function Spell:get_target_n()
  return self.target_n
end

---@return string[]
function Spell:get_keywords()
  return self.keywords
end

---@return table
function Spell:get_description_params()
  local params = {}
  if self.effect and type(self.effect.amount) == "number" then
    params.amount = self.effect.amount
    params.amount_abs = math.abs(self.effect.amount)
  end
  if self.target_n then
    params.count = self.target_n
  end
  params.suspicion = self:get_suspicion_abs()
  params.suspicion_abs = self:get_suspicion_abs()
  return params
end

---@param target any
---@param hero any
---@return string|nil
function Spell:_resolve_target_side(target, hero)
  if type(target) == "table" then
    if target.faction == "hero" or target.faction == "enemy" then
      return target.faction
    end

    if target.primary then
      if hero and target.primary == hero then
        return "hero"
      end
      return "enemy"
    end

    if target.entities and #target.entities > 0 then
      local has_hero = false
      local has_enemy = false
      for _, entity in ipairs(target.entities) do
        if hero and entity == hero then
          has_hero = true
        else
          has_enemy = true
        end
      end
      if has_hero and has_enemy then
        return "both"
      end
      if has_hero then
        return "hero"
      end
      if has_enemy then
        return "enemy"
      end
    end
  end

  if target and hero and target == hero then
    return "hero"
  end
  if target then
    return "enemy"
  end
  return nil
end

---@param target any
---@param hero any
---@return number
function Spell:get_signed_suspicion_delta(target, hero)
  local abs_value = self:get_suspicion_abs()
  if abs_value == 0 then
    return 0
  end

  if self.target_mode == "action_next_n" or self.target_mode == "action_next_all" then
    if type(target) == "table" and type(target.applied_suspicion_delta) == "number" then
      return target.applied_suspicion_delta
    end
    return 0
  end

  local side = self:_resolve_target_side(target, hero)
  if side == "hero" then
    return -abs_value
  elseif side == "enemy" then
    return abs_value
  end

  return 0
end

---@return SpellEffectObject
function Spell:get_effect()
  return self.effect
end

---@return string
function Spell:get_timeline_type()
  return self.timeline_type
end

--- Check if this spell can be played given current mana
---@param mana_manager ManaManager
---@return boolean
function Spell:can_play(mana_manager)
  return mana_manager:can_afford(self.cost)
end

--- Reserve mana for this spell (timeline placement)
---@param mana_manager ManaManager
---@return boolean
function Spell:reserve(mana_manager)
  return mana_manager:reserve(self.cost)
end

--- Unreserve mana for this spell (timeline removal)
---@param mana_manager ManaManager
function Spell:unreserve(mana_manager)
  mana_manager:unreserve(self.cost)
end

--- Execute spell effect (after confirmation, during EXECUTION phase)
---@param target any
---@param context {hero: any, enemies: any, suspicion_manager: SuspicionManager}
function Spell:execute(target, context)
  if self.effect.type == "global" then
    self.effect:apply(target, context)
  elseif self.effect.type == "action_delta" or self.effect.type == "action_block" then
    self.effect:apply(target, context)
  else
    local targets = {}
    if type(target) == "table" and target.entities then
      targets = target.entities
    else
      targets[1] = target
    end

    for _, entity in ipairs(targets) do
      if entity and (not entity.is_alive or entity:is_alive()) then
        self.effect:apply(entity, context)
      end
    end
  end

  if context and context.suspicion_manager then
    local delta = self:get_signed_suspicion_delta(target, context.hero)
    if delta > 0 then
      context.suspicion_manager:add(delta)
    elseif delta < 0 then
      context.suspicion_manager:reduce(math.abs(delta))
    end
  end
end

--- Play this spell: spend mana + apply effect + suspicion (legacy compat)
---@param target any
---@param context {hero: any, enemies: any, mana_manager: ManaManager, suspicion_manager: SuspicionManager}
---@return boolean
function Spell:play(target, context)
  if not self:can_play(context.mana_manager) then
    return false
  end

  context.mana_manager:spend(self.cost)
  self:execute(target, context)
  return true
end

return Spell
