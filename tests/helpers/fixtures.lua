local EventBus = require('src.core.event_bus')
local Hero = require('src.combat.hero')
local Spell = require('src.spell.spell')
local SpellBook = require('src.spell.spell_book')
local ManaManager = require('src.spell.mana_manager')
local SuspicionManager = require('src.spell.suspicion_manager')
local RewardManager = require('src.reward.reward_manager')
local RewardCatalog = require('src.reward.reward_catalog')
local starter_spell_ids = require('data.spells.starter_spell_ids')

---@class RewardFixture
---@field hero Hero
---@field spell_book SpellBook
---@field mana_manager ManaManager
---@field suspicion_manager SuspicionManager
---@field reward_manager RewardManager

---@class TestFixtures
local Fixtures = {}

---@param ids string[]
---@return SpellBook
function Fixtures.create_spell_book(ids)
  local spells = {}
  for _, spell_id in ipairs(ids) do
    local data = RewardCatalog.get_spell_data(spell_id)
    if data then
      spells[#spells + 1] = Spell:new(data)
    end
  end
  return SpellBook:new(spells)
end

---@return RewardFixture
function Fixtures.create_reward_fixture()
  local hero = Hero:new({hp = 50, attack = 8, defense = 2, speed = 8})
  local spell_book = Fixtures.create_spell_book(starter_spell_ids)
  local mana_manager = ManaManager:new(100)
  local suspicion_manager = SuspicionManager:new(EventBus:new())
  local reward_manager = RewardManager:new(hero, spell_book, mana_manager, suspicion_manager)
  return {
    hero = hero,
    spell_book = spell_book,
    mana_manager = mana_manager,
    suspicion_manager = suspicion_manager,
    reward_manager = reward_manager,
  }
end

return Fixtures
