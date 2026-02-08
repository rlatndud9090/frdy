local class = require('lib.middleclass')

---@class Edge
---@field from_node Node
---@field to_node Node
local Edge = class('Edge')

---@param from_node Node
---@param to_node Node
function Edge:initialize(from_node, to_node)
  self.from_node = from_node
  self.to_node = to_node
end

---@return Node
function Edge:get_from_node()
  return self.from_node
end

---@return Node
function Edge:get_to_node()
  return self.to_node
end

---@return boolean
function Edge:is_available()
  return true
end

return Edge
