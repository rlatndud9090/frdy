local TestHelper = require('tests.test_helper')
local Fixtures = require('tests.helpers.fixtures')
local RewardCatalog = require('src.reward.reward_catalog')
local Spell = require('src.spell.spell')

local suite = {}

---@return nil
function suite.test_run_model_snapshots_restore_expected_progress()
  local fixture = Fixtures.create_reward_fixture(404)

  fixture.hero:add_action_pattern(RewardCatalog.get_pattern_data('hero_power_slash'))
  fixture.hero:upgrade_action_pattern('hero_power_slash')
  fixture.hero:increase_mental_load(1.4)
  fixture.hero:add_experience(140)

  local extra_spell = Spell:new(RewardCatalog.get_spell_data('time_warp'))
  extra_spell.cost = 17
  extra_spell.reward_rank = 3
  fixture.spell_book:add_spell(extra_spell)

  fixture.mana_manager:spend(22)
  fixture.suspicion_manager:add(13)

  fixture.reward_manager:enqueue_offer('legendary_item', 'elite_combat', 1)
  local offer = fixture.reward_manager:peek_offer()
  TestHelper.assert_true(offer ~= nil, "현재 보상 오퍼가 생성되어야 합니다.")
  TestHelper.assert_true(fixture.reward_manager:_add_legendary_item('ember_crown'))

  local hero_snapshot = fixture.hero:persistent_snapshot()
  local spell_book_snapshot = fixture.spell_book:snapshot()
  local mana_snapshot = fixture.mana_manager:snapshot()
  local suspicion_snapshot = fixture.suspicion_manager:snapshot()
  local reward_snapshot = fixture.reward_manager:snapshot()

  local restored = Fixtures.create_reward_fixture(404)
  restored.hero:restore_persistent_snapshot(hero_snapshot)
  restored.spell_book:restore(spell_book_snapshot)
  restored.mana_manager:restore_snapshot(mana_snapshot)
  restored.suspicion_manager:restore_snapshot(suspicion_snapshot)
  restored.reward_manager:restore(reward_snapshot)
  restored.reward_manager:set_runtime_refs(restored.hero, restored.spell_book, restored.mana_manager, restored.suspicion_manager)

  TestHelper.assert_equal(restored.hero:get_level(), fixture.hero:get_level())
  TestHelper.assert_equal(restored.hero:get_experience(), fixture.hero:get_experience())
  TestHelper.assert_near(restored.hero:get_mental_load(), fixture.hero:get_mental_load(), 1e-6)
  TestHelper.assert_true(restored.hero:has_action_pattern('hero_power_slash'))
  TestHelper.assert_equal(restored.spell_book:get_spell_by_id('time_warp'):get_cost(), 17)
  TestHelper.assert_equal(restored.spell_book:get_spell_by_id('time_warp').reward_rank, 3)
  TestHelper.assert_equal(restored.mana_manager:get_current(), fixture.mana_manager:get_current())
  TestHelper.assert_equal(restored.suspicion_manager:get_level(), fixture.suspicion_manager:get_level())
  TestHelper.assert_equal(restored.reward_manager:get_legendary_inventory():get_count(), 1)
  TestHelper.assert_true(restored.reward_manager:get_legendary_inventory():has_item('ember_crown'))
  TestHelper.assert_equal(restored.reward_manager:peek_offer().category, offer.category)
  TestHelper.assert_equal(restored.hero.attack, fixture.hero.attack)
end

return suite
