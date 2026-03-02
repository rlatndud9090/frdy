local TestHelper = require('tests.test_helper')
local Fixtures = require('tests.helpers.fixtures')
local RewardCatalog = require('src.reward.reward_catalog')
local Spell = require('src.spell.spell')

local suite = {}

---@return nil
function suite.test_non_insert_confirmation_only_counts_non_insert_spells()
  local fixture = Fixtures.create_reward_fixture()
  local reward_manager = fixture.reward_manager
  local awakening = reward_manager:get_demon_awakening()
  local spell_data = RewardCatalog.get_spell_data("heal_heavy")
  local spell = Spell:new(spell_data)

  reward_manager:on_non_insert_spells_confirmed({
    {type = "insert", spell = spell},
    {type = "global", spell = spell},
    {type = "manipulate_swap", spell = spell},
  })

  TestHelper.assert_equal(awakening:get_total_spent(), spell:get_cost() * 2)
  TestHelper.assert_equal(awakening:get_progress(), spell:get_cost() * 2)
  TestHelper.assert_equal(awakening:consume_pending_rewards(), 0)
end

---@return nil
function suite.test_non_insert_confirmation_can_generate_multiple_rewards()
  local fixture = Fixtures.create_reward_fixture()
  local reward_manager = fixture.reward_manager
  local awakening = reward_manager:get_demon_awakening()
  local spell_data = RewardCatalog.get_spell_data("heal_heavy")
  local spell = Spell:new(spell_data)

  reward_manager:on_non_insert_spells_confirmed({
    {type = "global", spell = spell},
    {type = "global", spell = spell},
    {type = "global", spell = spell},
    {type = "global", spell = spell},
    {type = "global", spell = spell},
  })

  TestHelper.assert_equal(awakening:get_total_spent(), spell:get_cost() * 5)
  TestHelper.assert_equal(awakening:consume_pending_rewards(), 1)
  TestHelper.assert_equal(awakening:get_progress(), 10)
end

return suite
