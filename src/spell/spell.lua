local class = require('lib.middleclass')
local i18n = require('src.i18n.init')
local StatusRegistry = require('src.combat.status_registry')

---@class Spell
---@field id string
---@field name string
---@field description string
---@field desc_key string|nil
---@field cost number
---@field suspicion_delta number
---@field suspicion_abs number
---@field reward_rank number
---@field max_reward_rank number
---@field upgrade table|nil
---@field target_mode string "char_single"|"char_faction"|"char_all"|"action_next_n"|"action_next_all"|"field"
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

  if effect.type == "apply_field_status" then
    return "field"
  end

  if effect.type == "action_delta" or effect.type == "action_block" then
    return "action_next_n"
  end

  return "char_single"
end

---@param _target_mode string
---@param effect SpellEffectObject|nil
---@return string[]
local function infer_keywords(_target_mode, effect)
  local list = {}

  local function add(key)
    for _, existing in ipairs(list) do
      if existing == key then
        return
      end
    end
    list[#list + 1] = key
  end

  -- 키워드는 "차단"처럼 축약 의미가 필요한 경우만 자동 부여한다.
  -- 대상 범위(개별/진영/전체)나 일반 수치변경은 키워드로 자동 노출하지 않는다.
  if effect then
    if effect.type == "action_block" then
      add("block")
    end
  end

  return list
end

---@param dst table
---@param src table|nil
---@return nil
local function merge_params(dst, src)
  if not src then
    return
  end
  for key, value in pairs(src) do
    dst[key] = value
  end
end

---@param value any
---@return any
local function deep_copy(value)
  if type(value) ~= 'table' then
    return value
  end
  local copied = {}
  for k, v in pairs(value) do
    copied[k] = deep_copy(v)
  end
  return copied
end

---@param payload table|nil
---@return number|nil
local function first_number_from_payload(payload)
  if not payload then
    return nil
  end

  local prioritized_keys = {
    "amount",
    "damage",
    "attack_bonus",
    "attack_penalty",
    "speed_bonus",
    "speed_penalty",
    "attack_gain_per_hit",
  }

  for _, key in ipairs(prioritized_keys) do
    if type(payload[key]) == "number" then
      return payload[key]
    end
  end

  for _, value in pairs(payload) do
    if type(value) == "number" then
      return value
    end
  end
  return nil
end

---@param effect SpellEffectObject|nil
---@return table
local function build_status_preview_params(effect)
  if not effect or (effect.type ~= "apply_status" and effect.type ~= "apply_field_status") then
    return {}
  end

  local params = {}
  local spec = effect.status_spec or {}
  local payload = spec.payload or {}
  local status_id = effect.status_id
  local definition = status_id and StatusRegistry.get(status_id) or nil
  local stacks = 1
  if type(spec.stacks) == "number" then
    stacks = math.max(1, math.floor(spec.stacks))
  end

  if definition and type(definition.preview_params) == "function" then
    merge_params(params, definition.preview_params(payload, stacks, spec))
  end

  local amount = nil
  if type(spec.preview_amount) == "number" then
    amount = spec.preview_amount
  elseif type(params.amount) == "number" then
    amount = params.amount
  elseif type(effect.amount) == "number" and effect.amount ~= 0 then
    amount = effect.amount
  else
    amount = first_number_from_payload(payload)
  end

  if type(amount) == "number" then
    params.amount = amount
    params.amount_abs = math.abs(amount)
  end

  if params.ratio_percent == nil and type(payload.attack_reduction_ratio) == "number" then
    local ratio = math.max(0, payload.attack_reduction_ratio) * (stacks or 1)
    params.ratio_percent = math.floor(ratio * 100 + 0.5)
  end

  if spec.duration_turns ~= nil then
    params.duration_turns = spec.duration_turns
  end
  if spec.duration_actions ~= nil then
    params.duration_actions = spec.duration_actions
  end
  params.stacks = stacks

  return params
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
  self.reward_rank = data.reward_rank or 1
  self.max_reward_rank = data.max_reward_rank or 5
  self.upgrade = deep_copy(data.upgrade)
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
  local name_key = "spell.name." .. self.id
  local translated = i18n.t(name_key)
  if translated ~= name_key then
    return translated
  end
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

---@return {id: string, title: string, description: string, domain: string}[]
function Spell:get_status_entries()
  local effect = self.effect
  if not effect or (effect.type ~= "apply_status" and effect.type ~= "apply_field_status") then
    return {}
  end
  if not effect.status_id then
    return {}
  end

  local definition = StatusRegistry.get(effect.status_id)
  if not definition then
    return {}
  end

  local params = self:get_description_params()
  local title = definition.title_key and i18n.t(definition.title_key, params) or effect.status_id
  local description = definition.description_key and i18n.t(definition.description_key, params) or effect.status_id

  return {
    {
      id = effect.status_id,
      title = title,
      description = description,
      domain = definition.domain or "character",
    }
  }
end

---@return table
function Spell:get_description_params()
  local params = {}
  if self.effect and type(self.effect.amount) == "number" then
    params.amount = self.effect.amount
    params.amount_abs = math.abs(self.effect.amount)
  end
  if self.effect and (self.effect.type == "apply_status" or self.effect.type == "apply_field_status") then
    merge_params(params, build_status_preview_params(self.effect))
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
---@param context {hero: any, enemies: any, suspicion_manager: SuspicionManager, demon_awakening?: DemonAwakening}
function Spell:execute(target, context)
  if self.effect.type == "global" or self.effect.type == "apply_field_status" then
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

  if context and context.demon_awakening then
    context.demon_awakening:on_spell_executed(self.cost)
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

---@return table
function Spell:snapshot()
  return {
    id = self.id,
    name = self.name,
    description = self.description,
    desc_key = self.desc_key,
    cost = self.cost,
    suspicion_delta = self.suspicion_delta,
    suspicion_abs = self.suspicion_abs,
    reward_rank = self.reward_rank,
    max_reward_rank = self.max_reward_rank,
    upgrade = deep_copy(self.upgrade),
    target_mode = self.target_mode,
    target_n = self.target_n,
    keywords = deep_copy(self.keywords),
    effect = deep_copy(self.effect),
    timeline_type = self.timeline_type,
  }
end

---@param snapshot table
---@return Spell
function Spell.static.from_snapshot(snapshot)
  local spell = Spell:new({
    id = snapshot.id,
    name = snapshot.name,
    description = snapshot.description,
    desc_key = snapshot.desc_key,
    cost = snapshot.cost,
    suspicion_delta = snapshot.suspicion_delta,
    suspicion_abs = snapshot.suspicion_abs,
    reward_rank = snapshot.reward_rank,
    max_reward_rank = snapshot.max_reward_rank,
    upgrade = deep_copy(snapshot.upgrade),
    target_mode = snapshot.target_mode,
    target_n = snapshot.target_n,
    keywords = deep_copy(snapshot.keywords or {}),
    effect = deep_copy(snapshot.effect),
  })
  spell.timeline_type = snapshot.timeline_type or spell.timeline_type
  spell.suspicion_abs = snapshot.suspicion_abs or math.abs(spell.suspicion_delta or 0)
  return spell
end

return Spell
