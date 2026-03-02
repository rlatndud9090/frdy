local TestHelper = require('tests.test_helper')
local Fixtures = require('tests.helpers.fixtures')
local RewardCatalog = require('src.reward.reward_catalog')

local suite = {}

---@return nil
function suite.test_enqueue_offer_ignores_non_positive_counts()
  local fixture = Fixtures.create_reward_fixture()
  local reward_manager = fixture.reward_manager

  reward_manager:enqueue_offer("demon_spell", "test", 0)
  reward_manager:enqueue_offer("demon_spell", "test", -2)

  TestHelper.assert_equal(reward_manager:get_pending_offer_count(), 0)
  TestHelper.assert_false(reward_manager:has_pending_offers())
end

---@return nil
function suite.test_has_pending_offers_skips_unbuildable_legendary_offer()
  local fixture = Fixtures.create_reward_fixture()
  local reward_manager = fixture.reward_manager

  local all_ids = RewardCatalog.get_all_legendary_ids()
  for _, item_id in ipairs(all_ids) do
    TestHelper.assert_true(reward_manager:_add_legendary_item(item_id))
  end

  reward_manager:enqueue_offer("legendary_item", "test", 1)
  TestHelper.assert_false(reward_manager:has_pending_offers())
  TestHelper.assert_equal(reward_manager:get_pending_offer_count(), 0)
end

---@return nil
function suite.test_elite_settlement_offer_order_is_legendary_then_demon()
  local fixture = Fixtures.create_reward_fixture()
  local reward_manager = fixture.reward_manager
  local awakening = reward_manager:get_demon_awakening()
  awakening:on_spell_executed(100)

  local elite_node = {
    is_elite = function()
      return true
    end,
    is_boss = function()
      return false
    end
  }

  reward_manager:prepare_combat_settlement("victory", elite_node)

  local first_offer = reward_manager:peek_offer()
  TestHelper.assert_true(first_offer ~= nil)
  TestHelper.assert_equal(first_offer.category, "legendary_item")
  local _, first_applied = reward_manager:resolve_current_offer(first_offer.options[1])
  TestHelper.assert_true(first_applied)

  local second_offer = reward_manager:peek_offer()
  TestHelper.assert_true(second_offer ~= nil)
  TestHelper.assert_equal(second_offer.category, "demon_spell")
end

---@return nil
function suite.test_remove_owned_reward_respects_spell_minimum_holdings()
  local fixture = Fixtures.create_reward_fixture()
  local reward_manager = fixture.reward_manager

  local removed_without_extra = reward_manager:remove_owned_reward("demon_spell", 1, "random")
  TestHelper.assert_equal(removed_without_extra, 0)

  TestHelper.assert_true(reward_manager:_add_spell("heal_heavy"))
  local removed_with_extra = reward_manager:remove_owned_reward("demon_spell", 1, "id", "heal_heavy")
  TestHelper.assert_equal(removed_with_extra, 1)
end

return suite
