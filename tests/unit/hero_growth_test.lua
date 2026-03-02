local TestHelper = require('tests.test_helper')
local Hero = require('src.combat.hero')

local suite = {}

---@return nil
function suite.test_add_experience_applies_fixed_growth_per_level()
  local hero = Hero:new({hp = 50, attack = 8, defense = 2, speed = 8})

  local result = hero:add_experience(100)
  TestHelper.assert_equal(result.gained_levels, 1)
  TestHelper.assert_equal(result.crossed_milestones, 0)
  TestHelper.assert_equal(hero:get_level(), 2)
  TestHelper.assert_equal(hero:get_experience(), 0)
  TestHelper.assert_equal(hero:get_max_hp(), 55)
  TestHelper.assert_equal(hero:get_hp(), 55)
  TestHelper.assert_equal(hero:get_attack(), 9)
  TestHelper.assert_near(hero:get_speed(), 8.5)
end

---@return nil
function suite.test_add_experience_counts_multiple_milestones()
  local hero = Hero:new({hp = 50, attack = 8, defense = 2, speed = 8})

  local result = hero:add_experience(5500)
  TestHelper.assert_equal(result.gained_levels, 10)
  TestHelper.assert_equal(result.crossed_milestones, 2)
  TestHelper.assert_equal(hero:get_level(), 11)
  TestHelper.assert_equal(hero:get_experience(), 0)
  TestHelper.assert_equal(hero:get_max_hp(), 100)
  TestHelper.assert_equal(hero:get_attack(), 18)
  TestHelper.assert_near(hero:get_speed(), 13.0)
end

return suite
