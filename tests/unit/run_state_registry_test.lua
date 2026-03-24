local TestHelper = require('tests.test_helper')
local RunStateRegistry = require('src.core.run_state_registry')

local suite = {}

---@return nil
function suite.test_list_keys_preserves_registration_order()
  local registry = RunStateRegistry:new()
  registry:register({
    key = 'run_context',
    snapshot = function()
      return {}
    end,
    validate = function(snapshot)
      return snapshot, nil
    end,
    restore = function()
      return true, nil
    end,
  })
  registry:register({
    key = 'map_progress',
    snapshot = function()
      return {}
    end,
    validate = function(snapshot)
      return snapshot, nil
    end,
    restore = function()
      return true, nil
    end,
  })
  registry:register({
    key = 'hero',
    snapshot = function()
      return {}
    end,
    validate = function(snapshot)
      return snapshot, nil
    end,
    restore = function()
      return true, nil
    end,
  })

  local keys = registry:list_keys()
  TestHelper.assert_equal(#keys, 3)
  TestHelper.assert_equal(keys[1], 'run_context')
  TestHelper.assert_equal(keys[2], 'map_progress')
  TestHelper.assert_equal(keys[3], 'hero')
end

return suite
