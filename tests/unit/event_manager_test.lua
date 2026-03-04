local TestHelper = require('tests.test_helper')
local EventManager = require('src.event.event_manager')
local RNG = require('src.core.rng')

local suite = {}

---@return nil
function suite.test_same_seed_returns_same_event_sequence()
  local event_data = require('data.events.floor1_events')

  local manager_a = EventManager:new(RNG:new(1111))
  manager_a:load_events(event_data)

  local manager_b = EventManager:new(RNG:new(1111))
  manager_b:load_events(event_data)

  for _ = 1, 10 do
    local event_a = manager_a:get_random_event()
    local event_b = manager_b:get_random_event()
    TestHelper.assert_true(event_a ~= nil)
    TestHelper.assert_true(event_b ~= nil)
    TestHelper.assert_equal(event_a:get_id(), event_b:get_id())
  end
end

return suite
