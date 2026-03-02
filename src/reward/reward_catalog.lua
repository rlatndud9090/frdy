local RewardCatalog = {}

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

local base_spells = require('data.spells.base_spells')
local starter_spell_ids = require('data.spells.starter_spell_ids')
local hero_pattern_pool = require('data.rewards.hero_pattern_pool')
local legendary_item_pool = require('data.rewards.legendary_item_pool')

local spell_by_id = {}
local spell_ids = {}
for _, spell_data in ipairs(base_spells) do
  spell_by_id[spell_data.id] = spell_data
  spell_ids[#spell_ids + 1] = spell_data.id
end

local starter_lookup = {}
for _, spell_id in ipairs(starter_spell_ids) do
  starter_lookup[spell_id] = true
end

local hero_pattern_by_id = {}
local hero_pattern_ids = {}
for _, pattern_data in ipairs(hero_pattern_pool) do
  hero_pattern_by_id[pattern_data.id] = pattern_data
  hero_pattern_ids[#hero_pattern_ids + 1] = pattern_data.id
end

local legendary_by_id = {}
local legendary_ids = {}
for _, item_data in ipairs(legendary_item_pool) do
  legendary_by_id[item_data.id] = item_data
  legendary_ids[#legendary_ids + 1] = item_data.id
end

---@param spell_id string
---@return boolean
function RewardCatalog.is_starter_spell(spell_id)
  return starter_lookup[spell_id] == true
end

---@return string[]
function RewardCatalog.get_starter_spell_ids()
  return deep_copy(starter_spell_ids)
end

---@return string[]
function RewardCatalog.get_all_spell_ids()
  return deep_copy(spell_ids)
end

---@param spell_id string
---@return table|nil
function RewardCatalog.get_spell_data(spell_id)
  local data = spell_by_id[spell_id]
  if not data then
    return nil
  end
  return deep_copy(data)
end

---@return string[]
function RewardCatalog.get_all_pattern_ids()
  return deep_copy(hero_pattern_ids)
end

---@param pattern_id string
---@return table|nil
function RewardCatalog.get_pattern_data(pattern_id)
  local data = hero_pattern_by_id[pattern_id]
  if not data then
    return nil
  end
  return deep_copy(data)
end

---@return string[]
function RewardCatalog.get_all_legendary_ids()
  return deep_copy(legendary_ids)
end

---@param item_id string
---@return table|nil
function RewardCatalog.get_legendary_data(item_id)
  local data = legendary_by_id[item_id]
  if not data then
    return nil
  end
  return deep_copy(data)
end

return RewardCatalog
