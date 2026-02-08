local class = require('lib.middleclass')

---@class Map
---@field floors Floor[]
---@field current_floor_index number
---@field current_node Node|nil
local Map = class('Map')

function Map:initialize()
  self.floors = {}
  self.current_floor_index = 1
  self.current_node = nil
end

---@param floor Floor
function Map:add_floor(floor)
  table.insert(self.floors, floor)
end

---@return Floor|nil
function Map:get_current_floor()
  return self.floors[self.current_floor_index]
end

---@param index number
---@return Floor|nil
function Map:get_floor(index)
  return self.floors[index]
end

---@return number
function Map:get_total_floors()
  return #self.floors
end

function Map:advance_floor()
  self.current_floor_index = self.current_floor_index + 1
end

---@return Node|nil
function Map:get_current_node()
  return self.current_node
end

---@param node Node|nil
function Map:set_current_node(node)
  self.current_node = node
end

return Map
