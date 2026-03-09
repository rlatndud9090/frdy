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

---@return nil
function suite.test_load_events_is_idempotent_for_same_dataset()
  local event_data = require('data.events.floor1_events')
  local manager = EventManager:new(RNG:new(2222))
  local expected_count = #event_data

  manager:load_events(event_data)
  TestHelper.assert_equal(manager:get_event_count(), expected_count)

  manager:load_events(event_data)
  TestHelper.assert_equal(manager:get_event_count(), expected_count)

  for _, event in ipairs(event_data) do
    TestHelper.assert_true(manager:get_event(event.id) ~= nil)
  end
end

return suite
