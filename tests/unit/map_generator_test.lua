local TestHelper = require('tests.test_helper')
local MapGenerator = require('src.map.map_generator')
local RNG = require('src.core.rng')
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

---@param map Map
---@return string
local function map_signature(map)
  local floor = map:get_current_floor()
  local node_entries = {}
  local edge_entries = {}

  for _, node in ipairs(floor:get_nodes()) do
    local pos = node:get_position()
    local is_elite = node.is_elite and node:is_elite() or false
    node_entries[#node_entries + 1] = string.format(
      "%d|%s|%d|%.6f|%s|%s",
      node.id,
      node:get_type(),
      pos.x,
      pos.y,
      tostring(node:is_boss()),
      tostring(is_elite)
    )
  end

  for _, edge in ipairs(floor:get_edges()) do
    edge_entries[#edge_entries + 1] = string.format("%d>%d", edge:get_from_node().id, edge:get_to_node().id)
  end

  table.sort(node_entries)
  table.sort(edge_entries)
  return table.concat(node_entries, ",") .. "::" .. table.concat(edge_entries, ",")
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

---@return nil
function suite.test_same_seed_generates_identical_map_layout()
  local config = deep_copy(default_config)

  local generator_a = MapGenerator:new(RNG:new(20260302))
  local map_a = generator_a:generate_map(config)

  local generator_b = MapGenerator:new(RNG:new(20260302))
  local map_b = generator_b:generate_map(config)

  TestHelper.assert_equal(map_signature(map_a), map_signature(map_b))
end

return suite
