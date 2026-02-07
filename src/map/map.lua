local class = require('lib.middleclass')

---@class Map
---@field floors table Array of Floor instances
---@field current_floor_index integer Current floor index (1-based)
---@field current_node table|nil Current node instance
local Map = class('Map')

---Constructor
function Map:initialize()
  self.floors = {}
  self.current_floor_index = 1
  self.current_node = nil
end

---Add a floor to the map
---@param floor table Floor instance
function Map:add_floor(floor)
  table.insert(self.floors, floor)
end

---Get the current floor
---@return table|nil Floor instance
function Map:get_current_floor()
  return self.floors[self.current_floor_index]
end

---Get a specific floor by index
---@param index integer Floor index (1-based)
---@return table|nil Floor instance
function Map:get_floor(index)
  return self.floors[index]
end

---Get total number of floors
---@return integer
function Map:get_total_floors()
  return #self.floors
end

---Advance to the next floor
function Map:advance_floor()
  self.current_floor_index = self.current_floor_index + 1
end

---Get the current node
---@return table|nil Node instance
function Map:get_current_node()
  return self.current_node
end

---Set the current node
---@param node table|nil Node instance
function Map:set_current_node(node)
  self.current_node = node
end

return Map
