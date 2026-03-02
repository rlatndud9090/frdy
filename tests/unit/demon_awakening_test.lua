local TestHelper = require('tests.test_helper')
local DemonAwakening = require('src.reward.demon_awakening')

local suite = {}

---@return nil
function suite.test_threshold_accumulates_pending_rewards()
  local awakening = DemonAwakening:new({threshold = 100})

  local gained = awakening:on_spell_executed(230)
  TestHelper.assert_equal(gained, 2)
  TestHelper.assert_equal(awakening:get_progress(), 30)
  TestHelper.assert_equal(awakening:get_total_spent(), 230)

  local pending = awakening:consume_pending_rewards()
  TestHelper.assert_equal(pending, 2)
  TestHelper.assert_equal(awakening:consume_pending_rewards(), 0)
end

---@return nil
function suite.test_non_positive_cost_does_not_progress()
  local awakening = DemonAwakening:new({threshold = 50})

  TestHelper.assert_equal(awakening:on_spell_executed(0), 0)
  TestHelper.assert_equal(awakening:on_spell_executed(-10), 0)
  TestHelper.assert_equal(awakening:get_progress(), 0)
  TestHelper.assert_equal(awakening:get_total_spent(), 0)
end

return suite
