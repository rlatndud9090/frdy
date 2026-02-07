local class = require('lib.middleclass')

local Edge = class('Edge')

function Edge:initialize(from_node, to_node)
  self.from_node = from_node
  self.to_node = to_node
end

function Edge:get_from_node()
  return self.from_node
end

function Edge:get_to_node()
  return self.to_node
end

function Edge:is_available()
  return true
end

return Edge
