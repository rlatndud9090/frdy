local TestHelper = require('tests.test_helper')
local Hero = require('src.combat.hero')
local LegendaryInventory = require('src.reward.legendary_inventory')

local suite = {}

---@return nil
function suite.test_add_and_remove_item_applies_and_rolls_back_modifiers()
  local hero = Hero:new({hp = 50, attack = 8, defense = 2, speed = 8})
  local inventory = LegendaryInventory:new()
  local control_bonus = 0
  local reward_manager = {
    adjust_reward_control_bonus = function(_, delta)
      control_bonus = control_bonus + delta
    end
  }

  local item = {
    id = "test_relic",
    name_key = "item.test_relic.name",
    desc_key = "item.test_relic.desc",
    modifiers = {
      hero_max_hp = 6,
      hero_attack = 2,
      reward_control_max_stage_bonus = 1,
    },
  }

  TestHelper.assert_true(inventory:add_item(item, {hero = hero, reward_manager = reward_manager}))
  TestHelper.assert_equal(hero:get_max_hp(), 56)
  TestHelper.assert_equal(hero:get_hp(), 56)
  TestHelper.assert_equal(hero:get_attack(), 10)
  TestHelper.assert_equal(control_bonus, 1)
  TestHelper.assert_equal(inventory:get_count(), 1)

  local removed = inventory:remove_by_id("test_relic", {hero = hero, reward_manager = reward_manager})
  TestHelper.assert_true(removed ~= nil)
  TestHelper.assert_equal(hero:get_max_hp(), 50)
  TestHelper.assert_equal(hero:get_hp(), 50)
  TestHelper.assert_equal(hero:get_attack(), 8)
  TestHelper.assert_equal(control_bonus, 0)
  TestHelper.assert_equal(inventory:get_count(), 0)
end

---@return nil
function suite.test_get_owned_ids_returns_defensive_copy()
  local inventory = LegendaryInventory:new()
  local item_a = {id = "a", name_key = "a", desc_key = "a", modifiers = {}}
  local item_b = {id = "b", name_key = "b", desc_key = "b", modifiers = {}}

  TestHelper.assert_true(inventory:add_item(item_a, {}))
  TestHelper.assert_true(inventory:add_item(item_b, {}))
  local owned_ids = inventory:get_owned_ids()
  owned_ids[1] = "tampered"
  owned_ids[3] = "new"

  local fresh_ids = inventory:get_owned_ids()
  TestHelper.assert_equal(#fresh_ids, 2)
  TestHelper.assert_true(inventory:has_item("a"))
  TestHelper.assert_true(inventory:has_item("b"))
end

return suite
