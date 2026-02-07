local Map = require('src.map.map')

-- Create a map instance
local map = Map:new()

-- Test initial state
assert(map:get_total_floors() == 0, "Initial floor count should be 0")
assert(map.current_floor_index == 1, "Initial floor index should be 1")
assert(map:get_current_node() == nil, "Initial current node should be nil")

-- Test add_floor
local mock_floor_1 = {id = 1, name = "Floor 1"}
local mock_floor_2 = {id = 2, name = "Floor 2"}
map:add_floor(mock_floor_1)
map:add_floor(mock_floor_2)

assert(map:get_total_floors() == 2, "Should have 2 floors")

-- Test get_current_floor
local current = map:get_current_floor()
assert(current.id == 1, "Current floor should be floor 1")

-- Test get_floor
local floor2 = map:get_floor(2)
assert(floor2.id == 2, "get_floor(2) should return floor 2")

-- Test advance_floor
map:advance_floor()
assert(map.current_floor_index == 2, "Floor index should be 2 after advance")
assert(map:get_current_floor().id == 2, "Current floor should now be floor 2")

-- Test set_current_node and get_current_node
local mock_node = {id = "node_1", type = "combat"}
map:set_current_node(mock_node)
assert(map:get_current_node().id == "node_1", "Current node should be set")

print("All Map tests passed!")
