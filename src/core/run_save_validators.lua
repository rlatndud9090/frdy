local RunContext = require('src.core.run_context')
local RNG = require('src.core.rng')
local SaveSanitizer = require('src.core.save_sanitizer')

---@class RunSaveValidators
local RunSaveValidators = {}

local CHECKPOINT_KINDS = {
  start_node_select = true,
  combat_start = true,
  event_start = true,
  reward_offer_presented = true,
  path_ready = true,
}

local ACTION_PATTERN_TYPES = {
  attack = true,
  defend = true,
  heal = true,
  buff = true,
  debuff = true,
}

local ACTION_PATTERN_CONDITIONS = {
  always = true,
  hp_below = true,
  hp_above = true,
  target_hp_below = true,
  enemy_count_above = true,
  fallback = true,
}

---@param snapshot any
---@return table|nil
function RunSaveValidators.action_pattern(snapshot)
  if type(snapshot) ~= "table" then
    return nil
  end

  return {
    id = SaveSanitizer.string(snapshot.id, "pattern"),
    name = SaveSanitizer.string(snapshot.name, SaveSanitizer.string(snapshot.id, "pattern")),
    type = SaveSanitizer.enum(snapshot.type, ACTION_PATTERN_TYPES, "attack"),
    priority = SaveSanitizer.integer(snapshot.priority, 0, 0, 9999),
    condition = SaveSanitizer.enum(snapshot.condition, ACTION_PATTERN_CONDITIONS, "always"),
    condition_params = SaveSanitizer.plain_data(snapshot.condition_params) or {},
    cooldown = SaveSanitizer.integer(snapshot.cooldown, 0, 0, 999),
    params = SaveSanitizer.plain_data(snapshot.params) or {},
    reward_rank = SaveSanitizer.integer(snapshot.reward_rank, 0, 0, 99),
    max_reward_rank = SaveSanitizer.integer(snapshot.max_reward_rank, 0, 0, 99),
  }
end

---@param snapshot any
---@return table|nil
function RunSaveValidators.hero(snapshot)
  if type(snapshot) ~= "table" then
    return nil
  end

  return {
    hp = SaveSanitizer.number(snapshot.hp, 50, 0, 999999),
    max_hp = SaveSanitizer.number(snapshot.max_hp, 50, 1, 999999),
    attack = SaveSanitizer.number(snapshot.attack, 8, 0, 999999),
    defense = SaveSanitizer.number(snapshot.defense, 2, 0, 999999),
    speed = SaveSanitizer.number(snapshot.speed, 8, 0, 999999),
    level = SaveSanitizer.integer(snapshot.level, 1, 1, 9999),
    experience = SaveSanitizer.integer(snapshot.experience, 0, 0, 99999999),
    mental_load = SaveSanitizer.number(snapshot.mental_load, 0, 0, 999999),
    current_turn = SaveSanitizer.integer(snapshot.current_turn, 0, 0, 999999),
    cooldown_tracker = SaveSanitizer.string_key_map(snapshot.cooldown_tracker, function(value)
      return SaveSanitizer.integer(value, 0, 0, 999999)
    end),
    action_patterns = SaveSanitizer.array(snapshot.action_patterns, function(item)
      return RunSaveValidators.action_pattern(item)
    end),
  }
end

---@param snapshot any
---@return table|nil
function RunSaveValidators.spell(snapshot)
  if type(snapshot) ~= "table" then
    return nil
  end

  return {
    id = SaveSanitizer.string(snapshot.id, "spell"),
    name = SaveSanitizer.string(snapshot.name, SaveSanitizer.string(snapshot.id, "spell")),
    description = SaveSanitizer.string(snapshot.description, ""),
    desc_key = type(snapshot.desc_key) == "string" and snapshot.desc_key or nil,
    cost = SaveSanitizer.integer(snapshot.cost, 0, 0, 999999),
    suspicion_delta = SaveSanitizer.number(snapshot.suspicion_delta, 0, -999999, 999999),
    suspicion_abs = SaveSanitizer.number(snapshot.suspicion_abs, 0, 0, 999999),
    reward_rank = SaveSanitizer.integer(snapshot.reward_rank, 0, 0, 99),
    max_reward_rank = SaveSanitizer.integer(snapshot.max_reward_rank, 0, 0, 99),
    upgrade = SaveSanitizer.plain_data(snapshot.upgrade),
    target_mode = SaveSanitizer.string(snapshot.target_mode, "char_single"),
    target_n = snapshot.target_n ~= nil and SaveSanitizer.integer(snapshot.target_n, 1, 1, 999) or nil,
    keywords = SaveSanitizer.array(snapshot.keywords, function(value)
      return SaveSanitizer.string(value, "")
    end),
    effect = SaveSanitizer.plain_data(snapshot.effect),
    timeline_type = SaveSanitizer.string(snapshot.timeline_type, "insert"),
  }
end

---@param snapshot any
---@return table|nil
function RunSaveValidators.spell_book(snapshot)
  if type(snapshot) ~= "table" then
    return nil
  end

  return {
    spells = SaveSanitizer.array(snapshot.spells, function(item)
      return RunSaveValidators.spell(item)
    end),
    used_this_turn = SaveSanitizer.string_key_map(snapshot.used_this_turn, function(value)
      return SaveSanitizer.integer(value, 0, 0, 9999)
    end),
    reserved = SaveSanitizer.string_key_map(snapshot.reserved, function(value)
      return SaveSanitizer.integer(value, 0, 0, 9999)
    end),
    reserved_stack = SaveSanitizer.array(snapshot.reserved_stack, function(value)
      return SaveSanitizer.string(value, "")
    end),
  }
end

---@param snapshot any
---@return table|nil
function RunSaveValidators.mana(snapshot)
  if type(snapshot) ~= "table" then
    return nil
  end

  local max_mana = SaveSanitizer.number(snapshot.max_mana, 100, 1, 999999)
  return {
    current_mana = SaveSanitizer.number(snapshot.current_mana, max_mana, 0, max_mana),
    max_mana = max_mana,
    reserved_mana = SaveSanitizer.number(snapshot.reserved_mana, 0, 0, max_mana),
  }
end

---@param snapshot any
---@return table|nil
function RunSaveValidators.suspicion(snapshot)
  if type(snapshot) ~= "table" then
    return nil
  end

  local max_level = SaveSanitizer.number(snapshot.max_level, 100, 1, 999999)
  return {
    level = SaveSanitizer.number(snapshot.level, 0, 0, max_level),
    max_level = max_level,
  }
end

---@param snapshot any
---@return table|nil
function RunSaveValidators.demon_awakening(snapshot)
  if type(snapshot) ~= "table" then
    return nil
  end

  local threshold = SaveSanitizer.integer(snapshot.threshold, 100, 1, 999999)
  return {
    threshold = threshold,
    progress = SaveSanitizer.integer(snapshot.progress, 0, 0, threshold),
    pending_rewards = SaveSanitizer.integer(snapshot.pending_rewards, 0, 0, 999999),
    total_spent = SaveSanitizer.integer(snapshot.total_spent, 0, 0, 999999999),
  }
end

---@param snapshot any
---@return table|nil
function RunSaveValidators.legendary_inventory(snapshot)
  if type(snapshot) ~= "table" then
    return nil
  end

  return {
    owned_ids = SaveSanitizer.array(snapshot.owned_ids, function(value)
      return SaveSanitizer.string(value, "")
    end),
    reward_control_bonus = SaveSanitizer.integer(snapshot.reward_control_bonus, 0, 0, 999),
  }
end

---@param snapshot any
---@return table|nil
function RunSaveValidators.reward(snapshot)
  if type(snapshot) ~= "table" then
    return nil
  end

  return {
    offer_queue = SaveSanitizer.plain_data(snapshot.offer_queue) or {},
    current_offer = SaveSanitizer.plain_data(snapshot.current_offer),
    demon_awakening = snapshot.demon_awakening and RunSaveValidators.demon_awakening(snapshot.demon_awakening) or nil,
    legendary_inventory = snapshot.legendary_inventory and RunSaveValidators.legendary_inventory(snapshot.legendary_inventory) or nil,
    reward_control_bonus_stage = SaveSanitizer.integer(snapshot.reward_control_bonus_stage, 0, 0, 999),
  }
end

---@param snapshot any
---@return table|nil
function RunSaveValidators.rng(snapshot)
  if type(snapshot) ~= "table" then
    return nil
  end

  local seed = RNG.normalize_seed(snapshot.seed or 1)
  return {
    seed = seed,
    state = RNG.normalize_seed(snapshot.state or seed),
    draw_count = SaveSanitizer.integer(snapshot.draw_count, 0, 0, 999999999),
  }
end

---@param snapshot any
---@return table|nil
function RunSaveValidators.run_context(snapshot)
  if type(snapshot) ~= "table" then
    return nil
  end

  return {
    run_seed = RunContext.normalize_seed(snapshot.run_seed or 1),
    streams = SaveSanitizer.string_key_map(snapshot.streams, function(value)
      return RunSaveValidators.rng(value)
    end),
  }
end

---@param snapshot any
---@return table|nil
function RunSaveValidators.map_progress(snapshot)
  if type(snapshot) ~= "table" then
    return nil
  end

  local completed_node_ids = SaveSanitizer.array(snapshot.completed_node_ids, function(value)
    return SaveSanitizer.integer(value, 0, 0, 999999999)
  end)
  table.sort(completed_node_ids)

  return {
    current_floor_index = SaveSanitizer.integer(snapshot.current_floor_index, 1, 1, 999),
    current_node_id = snapshot.current_node_id ~= nil
      and SaveSanitizer.integer(snapshot.current_node_id, 0, 0, 999999999)
      or nil,
    completed_node_ids = completed_node_ids,
  }
end

---@param save_data any
---@return table|nil
---@return string|nil
function RunSaveValidators.save_payload(save_data)
  if type(save_data) ~= "table" then
    return nil, "세이브 payload가 테이블이 아닙니다."
  end

  local systems = save_data.systems
  if type(systems) ~= "table" then
    systems = {
      run_context = save_data.run_context_snapshot,
      map_progress = save_data.map_progress,
      hero = save_data.hero_snapshot,
      spell_book = save_data.spell_book_snapshot,
      mana = save_data.mana_snapshot,
      suspicion = save_data.suspicion_snapshot,
      reward = save_data.reward_snapshot,
    }
  end

  local checkpoint = save_data.checkpoint or {}
  return {
    version = SaveSanitizer.integer(save_data.version, 1, 1, 999),
    run_seed = RunContext.normalize_seed(save_data.run_seed or 1),
    checkpoint = {
      kind = SaveSanitizer.enum(checkpoint.kind, CHECKPOINT_KINDS, "start_node_select"),
    },
    systems = {
      run_context = RunSaveValidators.run_context(systems.run_context),
      map_progress = RunSaveValidators.map_progress(systems.map_progress),
      hero = RunSaveValidators.hero(systems.hero),
      spell_book = RunSaveValidators.spell_book(systems.spell_book),
      mana = RunSaveValidators.mana(systems.mana),
      suspicion = RunSaveValidators.suspicion(systems.suspicion),
      reward = RunSaveValidators.reward(systems.reward),
    },
  }, nil
end

return RunSaveValidators
