local class = require('lib.middleclass')
local i18n = require('src.i18n.init')
local Spell = require('src.spell.spell')
local RewardCatalog = require('src.reward.reward_catalog')
local DemonAwakening = require('src.reward.demon_awakening')
local LegendaryInventory = require('src.reward.legendary_inventory')

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

---@class RewardManager
---@field hero Hero
---@field spell_book SpellBook
---@field mana_manager ManaManager
---@field suspicion_manager SuspicionManager
---@field offer_queue RewardOffer[]
---@field demon_awakening DemonAwakening
---@field legendary_inventory LegendaryInventory
---@field reward_control_bonus_stage number
local RewardManager = class('RewardManager')

---@param hero Hero
---@param spell_book SpellBook
---@param mana_manager ManaManager
---@param suspicion_manager SuspicionManager
function RewardManager:initialize(hero, spell_book, mana_manager, suspicion_manager)
  self.hero = hero
  self.spell_book = spell_book
  self.mana_manager = mana_manager
  self.suspicion_manager = suspicion_manager
  self.offer_queue = {}
  self.demon_awakening = DemonAwakening:new(config.demon_awakening)
  self.legendary_inventory = LegendaryInventory:new()
  self.reward_control_bonus_stage = 0
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
  return #self.offer_queue > 0
end

---@return RewardOffer|nil
function RewardManager:peek_offer()
  local offer = self.offer_queue[1]
  if not offer then
    return nil
  end
  offer.control = self:get_reward_control_rule()
  return offer
end

---@return number
function RewardManager:get_pending_offer_count()
  return #self.offer_queue
end

---@param list string[]
---@param count number
---@return string[]
local function pick_unique_random(list, count)
  local working = {}
  for i = 1, #list do
    working[i] = list[i]
  end

  local picked = {}
  local max_pick = math.min(count, #working)
  for _ = 1, max_pick do
    local index = math.random(#working)
    picked[#picked + 1] = working[index]
    table.remove(working, index)
  end

  return picked
end

---@param spell Spell
---@return boolean
function RewardManager:_is_spell_upgradable(spell)
  local current_rank = spell.reward_rank or 1
  local max_rank = spell.max_reward_rank or (config.spell_upgrade and config.spell_upgrade.max_rank) or 5
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
  local iterations = math.max(1, math.floor(count or 1))
  for _ = 1, iterations do
    local offer = self:_build_offer(category, source)
    if offer then
      self.offer_queue[#self.offer_queue + 1] = offer
    end
  end
end

---@param option RewardOption|nil
---@return RewardOffer|nil
function RewardManager:resolve_current_offer(option)
  local offer = table.remove(self.offer_queue, 1)
  if not offer or not option then
    return offer
  end

  if offer.category == 'demon_spell' then
    if option.action == 'upgrade' then
      self:_upgrade_spell(option.id)
    else
      self:_add_spell(option.id)
    end
  elseif offer.category == 'hero_pattern' then
    if option.action == 'upgrade' then
      self.hero:upgrade_action_pattern(option.id, config.pattern_upgrade)
    else
      self:_add_pattern(option.id)
    end
  elseif offer.category == 'legendary_item' then
    self:_add_legendary_item(option.id)
  end

  return offer
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
  local requested = math.max(1, math.floor(count or 1))
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

  local max_rank = (config.spell_upgrade and config.spell_upgrade.max_rank) or 5
  local current_rank = spell.reward_rank or 1
  if current_rank >= max_rank then
    return false
  end

  spell.reward_rank = current_rank + 1
  spell.max_reward_rank = max_rank

  local cost_reduction = (config.spell_upgrade and config.spell_upgrade.cost_reduction) or 0
  spell.cost = math.max(0, (spell.cost or 0) - cost_reduction)

  local effect = spell:get_effect()
  local delta = (config.spell_upgrade and config.spell_upgrade.effect_amount_delta) or 0
  if effect and type(effect.amount) == 'number' and effect.amount ~= 0 then
    local sign = effect.amount > 0 and 1 or -1
    effect.amount = effect.amount + sign * delta
  elseif effect and effect.type == 'action_block' and spell.target_n then
    spell.target_n = spell.target_n + 1
  elseif effect and type(effect.payload) == 'table' then
    for k, v in pairs(effect.payload) do
      if type(v) == 'number' then
        local sign = v >= 0 and 1 or -1
        effect.payload[k] = v + sign * delta
        break
      end
    end
  end

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
  local index = math.random(#candidates)
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
  local index = math.random(#removable)
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
  local picked = pick_unique_random(ids, #ids)
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
        options[#options + 1] = {
          category = 'demon_spell',
          id = spell_id,
          action = 'add',
          display_text = i18n.t('reward.option.obtain', {name = spell_data.name}),
        }
      end
    end
  end

  return options
end

---@return RewardOption[]
function RewardManager:_build_hero_pattern_options()
  local ids = RewardCatalog.get_all_pattern_ids()
  local picked = pick_unique_random(ids, #ids)
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

  local picked = pick_unique_random(candidates, 3)
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

return RewardManager
