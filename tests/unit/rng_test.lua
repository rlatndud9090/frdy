local TestHelper = require('tests.test_helper')
local RNG = require('src.core.rng')
local RunContext = require('src.core.run_context')

local suite = {}

---@return nil
function suite.test_same_seed_produces_same_sequence()
  local left = RNG:new(12345)
  local right = RNG:new(12345)

  for _ = 1, 20 do
    TestHelper.assert_equal(left:next_int(1, 100000), right:next_int(1, 100000))
  end
end

---@return nil
function suite.test_snapshot_restore_replays_from_saved_state()
  local rng = RNG:new(777)

  for _ = 1, 5 do
    rng:next_int(1, 1000)
  end
  local snapshot = rng:snapshot()

  local expected = {}
  for i = 1, 8 do
    expected[i] = rng:next_int(1, 1000)
  end

  TestHelper.assert_true(rng:restore(snapshot))
  for i = 1, 8 do
    TestHelper.assert_equal(rng:next_int(1, 1000), expected[i])
  end
end

---@return nil
function suite.test_run_context_stream_lookup_order_does_not_change_stream_output()
  local context_a = RunContext:new(20260302)
  local context_b = RunContext:new(20260302)

  local map_a = context_a:get_stream('gameplay.map')
  local reward_a = context_a:get_stream('gameplay.reward')

  local reward_b = context_b:get_stream('gameplay.reward')
  local map_b = context_b:get_stream('gameplay.map')

  for _ = 1, 12 do
    TestHelper.assert_equal(map_a:next_int(1, 100000), map_b:next_int(1, 100000))
    TestHelper.assert_equal(reward_a:next_int(1, 100000), reward_b:next_int(1, 100000))
  end
end

return suite
