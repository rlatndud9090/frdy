local TestHelper = require('tests.test_helper')
local MapGenerator = require('src.map.map_generator')
local default_config = require('data.map_configs.default_config')

local suite = {}

---@param value any
---@return any
local function deep_copy(value)
  if type(value) ~= "table" then
    return value
  end
  local copied = {}
  for key, child in pairs(value) do
    copied[key] = deep_copy(child)
  end
  return copied
end

---@return nil
function suite.test_elite_interval_zero_does_not_crash_map_generation()
  local config = deep_copy(default_config)
  config.elite_hot_column_interval = 0

  for _ = 1, 10 do
    local generator = MapGenerator:new()
    local ok, map_or_err = pcall(function()
      return generator:generate_map(config)
    end)
    TestHelper.assert_true(ok, tostring(map_or_err))
    TestHelper.assert_true(map_or_err ~= nil)
  end
end

return suite
