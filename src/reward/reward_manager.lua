local class = require('lib.middleclass')
local i18n = require('src.i18n.init')
local Spell = require('src.spell.spell')
local RewardCatalog = require('src.reward.reward_catalog')
local DemonAwakening = require('src.reward.demon_awakening')
local LegendaryInventory = require('src.reward.legendary_inventory')
local RNG = require('src.core.rng')

local config = require('data.rewards.config')

---@class RewardOption
---@field category string
---@field id string
---@field action string
---@field display_text string
---@field description string|nil

---@class RewardOffer
---@field category string
---@field source string
---@field title_key string
---@field options RewardOption[]
---@field control {max_stage: number, mental_increase: number}

---@class RewardOfferRequest
---@field category string
---@field source string

---@class RewardManager
---@field hero Hero
---@field spell_book SpellBook
---@field mana_manager ManaManager
---@field suspicion_manager SuspicionManager
---@field offer_queue RewardOfferRequest[]
---@field current_offer RewardOffer|nil
---@field demon_awakening DemonAwakening
---@field legendary_inventory LegendaryInventory
---@field reward_control_bonus_stage number
---@field rng RNG
local RewardManager = class('RewardManager')

---@param value any
---@return any
local function deep_copy_table(value)
  if type(value) ~= 'table' then
    return value
  end
  local copied = {}
  for key, item in pairs(value) do
    copied[key] = deep_copy_table(item)
  end
  return copied
end

---@param spell_data table|nil
---@param spell_id string
---@return string
local function resolve_spell_name(spell_data, spell_id)
  local name_key = 'spell.name.' .. spell_id
  local localized_name = i18n.t(name_key)
  if localized_name == name_key then
    localized_name = spell_data and spell_data.name or spell_id
  end
  return localized_name
end

---@param offer_category string
---@param option RewardOption|nil
---@return RewardOption|nil
function RewardManager:_serialize_offer_option(offer_category, option)
  if type(option) ~= 'table' then
    return nil
  end

  return {
    category = option.category or offer_category,
    id = option.id,
    action = option.action,
  }
end

---@param offer RewardOffer|nil
---@return RewardOffer|nil
function RewardManager:_serialize_offer(offer)
  if type(offer) ~= 'table' then
    return nil
  end

  local serialized_options = {}
  for _, option in ipairs(offer.options or {}) do
    local serialized = self:_serialize_offer_option(offer.category, option)
    if serialized then
      serialized_options[#serialized_options + 1] = serialized
    end
  end

  return {
    category = offer.category,
    source = offer.source,
    title_key = offer.title_key,
    options = serialized_options,
    control = deep_copy_table(offer.control),
  }
end

---@param option RewardOption|nil
---@param offer_category string
---@return RewardOption|nil
function RewardManager:_hydrate_offer_option(option, offer_category)
  if type(option) ~= 'table' then
    return nil
  end

  local hydrated = deep_copy_table(option)
  hydrated.category = hydrated.category or offer_category

  if hydrated.category == 'demon_spell' then
    local spell = self:_find_spell(hydrated.id)
    local spell_data = RewardCatalog.get_spell_data(hydrated.id)
    local spell_name = spell and spell:get_name() or resolve_spell_name(spell_data, hydrated.id)
    local label_key = hydrated.action == 'upgrade' and 'reward.option.upgrade' or 'reward.option.obtain'
    hydrated.display_text = i18n.t(label_key, {name = spell_name})
    hydrated.description = nil
    return hydrated
  end

  if hydrated.category == 'hero_pattern' then
    local pattern_data = RewardCatalog.get_pattern_data(hydrated.id)
    local pattern_name = pattern_data and i18n.t(pattern_data.name) or hydrated.id
    local label_key = hydrated.action == 'upgrade' and 'reward.option.upgrade' or 'reward.option.obtain'
    hydrated.display_text = i18n.t(label_key, {name = pattern_name})
    hydrated.description = nil
    return hydrated
  end

  if hydrated.category == 'legendary_item' then
    local item_data = RewardCatalog.get_legendary_data(hydrated.id)
    if item_data then
      hydrated.display_text = i18n.t('reward.option.obtain', {name = i18n.t(item_data.name_key)})
      hydrated.description = i18n.t(item_data.desc_key)
    end
    return hydrated
  end

  return hydrated
end

---@param offer RewardOffer|nil
---@return RewardOffer|nil
function RewardManager:_hydrate_offer(offer)
  if type(offer) ~= 'table' then
    return nil
  end

  local hydrated = deep_copy_table(offer)
  local hydrated_options = {}
  for _, option in ipairs(offer.options or {}) do
    local hydrated_option = self:_hydrate_offer_option(option, offer.category)
    if hydrated_option then
      hydrated_options[#hydrated_options + 1] = hydrated_option
    end
  end
  hydrated.options = hydrated_options
  hydrated.control = self:get_reward_control_rule()
  return hydrated
end

---@param hero Hero
---@param spell_book SpellBook
---@param mana_manager ManaManager
---@param suspicion_manager SuspicionManager
---@param rng? RNG
function RewardManager:initialize(hero, spell_book, mana_manager, suspicion_manager, rng)
  self.hero = hero
  self.spell_book = spell_book
  self.mana_manager = mana_manager
  self.suspicion_manager = suspicion_manager
  self.offer_queue = {}
  self.current_offer = nil
  self.rng = rng or RNG:new(os.time())
  self.demon_awakening = DemonAwakening:new(config.demon_awakening)
  self.legendary_inventory = LegendaryInventory:new(self.rng)
  self.reward_control_bonus_stage = 0
end

---@param rng RNG
---@return nil
function RewardManager:set_rng(rng)
  self.rng = rng
  if self.legendary_inventory and self.legendary_inventory.set_rng then
    self.legendary_inventory:set_rng(rng)
  end
end

---@param hero Hero
---@param spell_book SpellBook
---@param mana_manager ManaManager
---@param suspicion_manager SuspicionManager
---@return nil
function RewardManager:set_runtime_refs(hero, spell_book, mana_manager, suspicion_manager)
  self.hero = hero
  self.spell_book = spell_book
  self.mana_manager = mana_manager
  self.suspicion_manager = suspicion_manager
end

---@return DemonAwakening
function RewardManager:get_demon_awakening()
  return self.demon_awakening
end

---@return LegendaryInventory
function RewardManager:get_legendary_inventory()
  return self.legendary_inventory
end

---@param delta number
---@return nil
function RewardManager:adjust_reward_control_bonus(delta)
  self.reward_control_bonus_stage = self.reward_control_bonus_stage + (delta or 0)
end

---@return {max_stage: number, mental_increase: number}
function RewardManager:get_reward_control_rule()
  return {
    max_stage = math.max(1, (config.reward_control.max_stage or 3) + self.reward_control_bonus_stage),
    mental_increase = config.reward_control.mental_increase or 0.25,
  }
end

---@return boolean
function RewardManager:has_pending_offers()
  if self.current_offer then
    return true
  end
  if #self.offer_queue == 0 then
    return false
  end
  return self:peek_offer() ~= nil
end

---@return RewardOffer|nil
function RewardManager:peek_offer()
  if self.current_offer then
    self.current_offer = self:_hydrate_offer(self.current_offer)
    return self.current_offer
  end

  while #self.offer_queue > 0 do
    local request = self.offer_queue[1]
    local offer = self:_build_offer(request.category, request.source)
    if offer then
      offer.control = self:get_reward_control_rule()
      self.current_offer = offer
      return offer
    end
    -- 현재 상태에서 생성 가능한 선택지가 없는 보상은 큐에서 제거한다.
    table.remove(self.offer_queue, 1)
  end

  self.current_offer = nil
  return nil
end

---@return number
function RewardManager:get_pending_offer_count()
  return #self.offer_queue
end

---@param list string[]
---@param count number
---@param rng RNG
---@return string[]
local function pick_unique_random(list, count, rng)
  local working = {}
  for i = 1, #list do
    working[i] = list[i]
  end

  local picked = {}
  local max_pick = math.min(count, #working)
  for _ = 1, max_pick do
    local index = rng:next_int(1, #working)
    picked[#picked + 1] = working[index]
    table.remove(working, index)
  end

  return picked
end

---@param raw_count number|nil
---@param default_count number
---@return number
local function normalize_iteration_count(raw_count, default_count)
  if raw_count == nil then
    return math.max(0, math.floor(default_count or 1))
  end
  return math.max(0, math.floor(raw_count))
end

---@param payload table|nil
---@param delta number
---@return boolean
local function bump_first_numeric_payload(payload, delta)
  if type(payload) ~= 'table' then
    return false
  end

  local preferred_keys = {
    'amount',
    'damage',
    'attack_bonus',
    'attack_penalty',
    'speed_bonus',
    'speed_penalty',
    'attack_gain_per_hit',
    'attack_reduction_ratio',
  }

  for _, key in ipairs(preferred_keys) do
    local value = payload[key]
    if type(value) == 'number' then
      local sign = value >= 0 and 1 or -1
      payload[key] = value + sign * delta
      return true
    end
  end

  -- Fallback: deterministic key order to avoid non-deterministic pairs() iteration.
  local numeric_keys = {}
  for key, value in pairs(payload) do
    if type(value) == 'number' then
      numeric_keys[#numeric_keys + 1] = key
    end
  end
  table.sort(numeric_keys, function(a, b)
    return tostring(a) < tostring(b)
  end)

  local key = numeric_keys[1]
  if key then
    local value = payload[key]
    local sign = value >= 0 and 1 or -1
    payload[key] = value + sign * delta
    return true
  end

  return false
end

---@param path string
---@return string[]
local function split_path(path)
  local parts = {}
  for token in string.gmatch(path, '[^%.]+') do
    parts[#parts + 1] = token
  end
  return parts
end

---@param root table
---@param path string
---@return table|nil, string|nil
local function resolve_path_parent(root, path)
  if type(root) ~= 'table' or type(path) ~= 'string' or path == '' then
    return nil, nil
  end

  local parts = split_path(path)
  if #parts == 0 then
    return nil, nil
  end

  local current = root
  for i = 1, #parts - 1 do
    local key = parts[i]
    local next_value = current[key]
    if type(next_value) ~= 'table' then
      return nil, nil
    end
    current = next_value
  end

  return current, parts[#parts]
end

---@param root table
---@param patch table
---@return boolean
local function apply_numeric_patch(root, patch)
  if type(root) ~= 'table' or type(patch) ~= 'table' then
    return false
  end

  local parent, key = resolve_path_parent(root, patch.path)
  if not parent or not key then
    return false
  end

  local current = parent[key]
  if type(current) ~= 'number' then
    return false
  end

  local mode = patch.mode or 'add'
  local value = patch.value or 0
  local next_value = current

  if mode == 'add' then
    next_value = current + value
  elseif mode == 'signed_add' then
    local sign = current >= 0 and 1 or -1
    next_value = current + sign * math.abs(value)
  elseif mode == 'multiply' then
    next_value = current * value
  else
    return false
  end

  if type(patch.min) == 'number' then
    next_value = math.max(patch.min, next_value)
  end
  if type(patch.max) == 'number' then
    next_value = math.min(patch.max, next_value)
  end

  if patch.round == 'floor' then
    next_value = math.floor(next_value)
  elseif patch.round == 'ceil' then
    next_value = math.ceil(next_value)
  elseif patch.round == 'round' then
    next_value = math.floor(next_value + 0.5)
  end

  parent[key] = next_value
  return true
end

---@param spell Spell
---@return boolean
function RewardManager:_is_spell_upgradable(spell)
  local current_rank = spell.reward_rank or 1
  local max_rank = (spell.upgrade and spell.upgrade.max_rank)
    or spell.max_reward_rank
    or (config.spell_upgrade and config.spell_upgrade.max_rank)
    or 5
  return current_rank < max_rank
end

---@param pattern ActionPattern
---@return boolean
function RewardManager:_is_pattern_upgradable(pattern)
  local current_rank = pattern.reward_rank or 1
  local max_rank = pattern.max_reward_rank or (config.pattern_upgrade and config.pattern_upgrade.max_rank) or 5
  return current_rank < max_rank
end

---@param category string
---@param source string
---@param count number|nil
---@return nil
function RewardManager:enqueue_offer(category, source, count)
  local iterations = normalize_iteration_count(count, 1)
  if iterations <= 0 then
    return
  end
  for _ = 1, iterations do
    self.offer_queue[#self.offer_queue + 1] = {
      category = category,
      source = source,
    }
  end
end

---@param offer RewardOffer
---@param option RewardOption
---@return boolean
function RewardManager:_is_option_in_offer(offer, option)
  for _, candidate in ipairs(offer.options or {}) do
    if candidate.id == option.id and candidate.action == option.action then
      return true
    end
  end
  return false
end

---@param offer RewardOffer
---@param option RewardOption
---@return boolean
function RewardManager:_apply_offer_option(offer, option)
  if offer.category == 'demon_spell' then
    if option.action == 'upgrade' then
      return self:_upgrade_spell(option.id)
    end
    return self:_add_spell(option.id)
  elseif offer.category == 'hero_pattern' then
    if option.action == 'upgrade' then
      return self.hero:upgrade_action_pattern(option.id, config.pattern_upgrade)
    end
    return self:_add_pattern(option.id)
  elseif offer.category == 'legendary_item' then
    return self:_add_legendary_item(option.id)
  end
  return false
end

---@param option RewardOption|nil
---@return RewardOffer|nil, boolean applied
function RewardManager:resolve_current_offer(option)
  local offer = self.current_offer or self:peek_offer()
  if not offer then
    return nil, false
  end
  if not option then
    return offer, false
  end

  if not self:_is_option_in_offer(offer, option) then
    return offer, false
  end

  local applied = self:_apply_offer_option(offer, option)
  self.current_offer = nil
  if applied then
    table.remove(self.offer_queue, 1)
  end

  return offer, applied
end

---@param result string
---@param node Node|nil
---@return nil
function RewardManager:prepare_combat_settlement(result, node)
  if result ~= 'victory' then
    return
  end

  local xp = config.hero_xp.normal or 30
  local is_boss = node and node.is_boss and node:is_boss() or false
  local is_elite = node and node.is_elite and node:is_elite() or false

  if is_boss then
    xp = config.hero_xp.boss or xp
  elseif is_elite then
    xp = config.hero_xp.elite or xp
  end

  if is_elite then
    self:enqueue_offer('legendary_item', 'elite_combat', 1)
  end

  self:grant_hero_experience(xp, 'combat_victory')

  local demon_rewards = self.demon_awakening:consume_pending_rewards()
  if demon_rewards > 0 then
    self:enqueue_offer('demon_spell', 'demon_awakening', demon_rewards)
  end
end

---@param amount number
---@param source string|nil
---@return HeroLevelResult
function RewardManager:grant_hero_experience(amount, source)
  local result = self.hero:add_experience(amount)
  if result.crossed_milestones > 0 then
    self:enqueue_offer('hero_pattern', source or 'experience', result.crossed_milestones)
  end
  return result
end

---@param interventions table[]|nil
---@return nil
function RewardManager:on_non_insert_spells_confirmed(interventions)
  if not interventions then
    return
  end

  for _, intervention in ipairs(interventions) do
    if intervention and intervention.spell and intervention.type ~= 'insert' then
      local cost = intervention.spell.get_cost and intervention.spell:get_cost() or 0
      self.demon_awakening:on_spell_executed(cost)
    end
  end
end

---@param category string
---@param count number
---@param mode string|nil
---@param id string|nil
---@return number removed_count
function RewardManager:remove_owned_reward(category, count, mode, id)
  local requested = normalize_iteration_count(count, 1)
  if requested <= 0 then
    return 0
  end
  local removed = 0

  if category == 'demon_spell' then
    for _ = 1, requested do
      if self:_remove_owned_spell(mode, id) then
        removed = removed + 1
      else
        break
      end
    end
  elseif category == 'hero_pattern' then
    for _ = 1, requested do
      if self:_remove_owned_pattern(mode, id) then
        removed = removed + 1
      else
        break
      end
    end
  elseif category == 'legendary_item' then
    for _ = 1, requested do
      if self:_remove_owned_legendary(mode, id) then
        removed = removed + 1
      else
        break
      end
    end
  end

  return removed
end

---@param category string
---@param source string
---@return RewardOffer|nil
function RewardManager:_build_offer(category, source)
  local options = {}
  if category == 'demon_spell' then
    options = self:_build_demon_spell_options()
  elseif category == 'hero_pattern' then
    options = self:_build_hero_pattern_options()
  elseif category == 'legendary_item' then
    options = self:_build_legendary_item_options()
  end

  if #options == 0 then
    return nil
  end

  return {
    category = category,
    source = source,
    title_key = 'reward.' .. category,
    options = options,
    control = self:get_reward_control_rule(),
  }
end

---@param spell_id string
---@return Spell|nil
function RewardManager:_find_spell(spell_id)
  local spells = self.spell_book:get_all_spells()
  for _, spell in ipairs(spells) do
    if spell:get_id() == spell_id then
      return spell
    end
  end
  return nil
end

---@param pattern_id string
---@return boolean
function RewardManager:_add_pattern(pattern_id)
  local pattern_data = RewardCatalog.get_pattern_data(pattern_id)
  if not pattern_data then
    return false
  end
  return self.hero:add_action_pattern(pattern_data)
end

---@param spell_id string
---@return boolean
function RewardManager:_add_spell(spell_id)
  local spell_data = RewardCatalog.get_spell_data(spell_id)
  if not spell_data then
    return false
  end
  if self:_find_spell(spell_id) then
    return self:_upgrade_spell(spell_id)
  end
  self.spell_book:add_spell(Spell:new(spell_data))
  return true
end

---@param spell_id string
---@return boolean
function RewardManager:_upgrade_spell(spell_id)
  local spell = self:_find_spell(spell_id)
  if not spell then
    return false
  end

  local upgrade = spell.upgrade or {}
  local max_rank = upgrade.max_rank
    or spell.max_reward_rank
    or (config.spell_upgrade and config.spell_upgrade.max_rank)
    or 5
  local current_rank = spell.reward_rank or 1
  if current_rank >= max_rank then
    return false
  end

  local applied_by_patch = false
  for _, patch_spec in ipairs(upgrade.patches or {}) do
    if apply_numeric_patch(spell, patch_spec) then
      applied_by_patch = true
    end
  end

  if not applied_by_patch then
    local cost_reduction = (config.spell_upgrade and config.spell_upgrade.cost_reduction) or 0
    spell.cost = math.max(0, (spell.cost or 0) - cost_reduction)

    local effect = spell:get_effect()
    local delta = (config.spell_upgrade and config.spell_upgrade.effect_amount_delta) or 0
    if effect and effect.type == 'action_block' and spell.target_n then
      spell.target_n = spell.target_n + 1
      if type(effect.amount) == 'number' then
        effect.amount = math.max(1, math.floor(spell.target_n))
      end
    elseif effect and type(effect.amount) == 'number' and effect.amount ~= 0 then
      local sign = effect.amount > 0 and 1 or -1
      effect.amount = effect.amount + sign * delta
      if (effect.type == 'apply_status' or effect.type == 'apply_field_status') and type(effect.status_spec) == 'table' then
        local status_spec = effect.status_spec
        if type(status_spec.preview_amount) == 'number' then
          local preview_sign = status_spec.preview_amount >= 0 and 1 or -1
          status_spec.preview_amount = status_spec.preview_amount + preview_sign * delta
        end
        bump_first_numeric_payload(status_spec.payload, delta)
      end
    elseif effect and type(effect.payload) == 'table' then
      bump_first_numeric_payload(effect.payload, delta)
    end
  end

  spell.reward_rank = current_rank + 1
  spell.max_reward_rank = max_rank
  return true
end

---@param item_id string
---@return boolean
function RewardManager:_add_legendary_item(item_id)
  local item_data = RewardCatalog.get_legendary_data(item_id)
  if not item_data then
    return false
  end
  return self.legendary_inventory:add_item(item_data, {
    hero = self.hero,
    reward_manager = self,
  })
end

---@param mode string|nil
---@param item_id string|nil
---@return boolean
function RewardManager:_remove_owned_spell(mode, item_id)
  local all_spells = self.spell_book:get_all_spells()
  if #all_spells <= (config.min_holdings and config.min_holdings.spells or 6) then
    return false
  end

  if mode == 'id' and item_id then
    local target = self:_find_spell(item_id)
    if not target then
      return false
    end
    if RewardCatalog.is_starter_spell(item_id) then
      return false
    end
    return self.spell_book:remove_spell(target)
  end

  local candidates = {}
  for _, spell in ipairs(all_spells) do
    local sid = spell:get_id()
    if not RewardCatalog.is_starter_spell(sid) then
      candidates[#candidates + 1] = spell
    end
  end

  if #candidates == 0 then
    return false
  end
  local index = self.rng:next_int(1, #candidates)
  return self.spell_book:remove_spell(candidates[index])
end

---@param mode string|nil
---@param pattern_id string|nil
---@return boolean
function RewardManager:_remove_owned_pattern(mode, pattern_id)
  local min_patterns = (config.min_holdings and config.min_holdings.patterns) or 2
  if self.hero:get_action_pattern_count() <= min_patterns then
    return false
  end

  if mode == 'id' and pattern_id then
    if pattern_id == 'hero_attack' or pattern_id == 'hero_guard' then
      return false
    end
    return self.hero:remove_action_pattern(pattern_id)
  end

  local removable = self.hero:get_removable_pattern_ids({'hero_attack', 'hero_guard'})
  if #removable == 0 then
    return false
  end
  local index = self.rng:next_int(1, #removable)
  return self.hero:remove_action_pattern(removable[index])
end

---@param mode string|nil
---@param item_id string|nil
---@return boolean
function RewardManager:_remove_owned_legendary(mode, item_id)
  local removed = nil
  if mode == 'id' and item_id then
    removed = self.legendary_inventory:remove_by_id(item_id, {
      hero = self.hero,
      reward_manager = self,
    })
  else
    removed = self.legendary_inventory:remove_random({
      hero = self.hero,
      reward_manager = self,
    })
  end
  return removed ~= nil
end

---@return RewardOption[]
function RewardManager:_build_demon_spell_options()
  local ids = RewardCatalog.get_all_spell_ids()
  local picked = pick_unique_random(ids, #ids, self.rng)
  local options = {}

  for _, spell_id in ipairs(picked) do
    if #options >= 3 then
      break
    end

    local owned_spell = self:_find_spell(spell_id)
    if owned_spell then
      if self:_is_spell_upgradable(owned_spell) then
        options[#options + 1] = {
          category = 'demon_spell',
          id = spell_id,
          action = 'upgrade',
          display_text = i18n.t('reward.option.upgrade', {name = owned_spell:get_name()}),
        }
      end
    else
      local spell_data = RewardCatalog.get_spell_data(spell_id)
      if spell_data then
        local localized_name = resolve_spell_name(spell_data, spell_id)
        options[#options + 1] = {
          category = 'demon_spell',
          id = spell_id,
          action = 'add',
          display_text = i18n.t('reward.option.obtain', {name = localized_name}),
        }
      end
    end
  end

  return options
end

---@return RewardOption[]
function RewardManager:_build_hero_pattern_options()
  local ids = RewardCatalog.get_all_pattern_ids()
  local picked = pick_unique_random(ids, #ids, self.rng)
  local options = {}

  for _, pattern_id in ipairs(picked) do
    if #options >= 3 then
      break
    end

    local pattern_data = RewardCatalog.get_pattern_data(pattern_id)
    if pattern_data then
      local pattern_name = i18n.t(pattern_data.name)
      if self.hero:has_action_pattern(pattern_id) then
        local pattern = self.hero:get_action_pattern(pattern_id)
        if pattern and self:_is_pattern_upgradable(pattern) then
          options[#options + 1] = {
            category = 'hero_pattern',
            id = pattern_id,
            action = 'upgrade',
            display_text = i18n.t('reward.option.upgrade', {name = pattern_name}),
          }
        end
      else
        options[#options + 1] = {
          category = 'hero_pattern',
          id = pattern_id,
          action = 'add',
          display_text = i18n.t('reward.option.obtain', {name = pattern_name}),
        }
      end
    end
  end

  return options
end

---@return RewardOption[]
function RewardManager:_build_legendary_item_options()
  local ids = RewardCatalog.get_all_legendary_ids()
  local candidates = {}
  for _, item_id in ipairs(ids) do
    if not self.legendary_inventory:has_item(item_id) then
      candidates[#candidates + 1] = item_id
    end
  end

  if #candidates == 0 then
    return {}
  end

  local picked = pick_unique_random(candidates, 3, self.rng)
  local options = {}
  for _, item_id in ipairs(picked) do
    local item_data = RewardCatalog.get_legendary_data(item_id)
    if item_data then
      options[#options + 1] = {
        category = 'legendary_item',
        id = item_id,
        action = 'add',
        display_text = i18n.t('reward.option.obtain', {name = i18n.t(item_data.name_key)}),
        description = i18n.t(item_data.desc_key),
      }
    end
  end

  return options
end

---@return table
function RewardManager:snapshot()
  return {
    offer_queue = deep_copy_table(self.offer_queue),
    current_offer = self:_serialize_offer(self.current_offer),
    demon_awakening = self.demon_awakening and self.demon_awakening:snapshot() or nil,
    legendary_inventory = self.legendary_inventory and self.legendary_inventory:snapshot() or nil,
    reward_control_bonus_stage = self.reward_control_bonus_stage,
  }
end

---@param snapshot table|nil
---@return nil
function RewardManager:restore(snapshot)
  if type(snapshot) ~= 'table' then
    return
  end

  self.offer_queue = deep_copy_table(snapshot.offer_queue or {})
  self.current_offer = self:_hydrate_offer(snapshot.current_offer)
  if self.demon_awakening and snapshot.demon_awakening then
    self.demon_awakening:restore(snapshot.demon_awakening)
  end
  if self.legendary_inventory and snapshot.legendary_inventory then
    self.legendary_inventory:restore(snapshot.legendary_inventory)
  end
  self.reward_control_bonus_stage = snapshot.reward_control_bonus_stage
    or (self.legendary_inventory and self.legendary_inventory:get_reward_control_bonus())
    or 0
end

return RewardManager
