local class = require('lib.middleclass')

local Node = class('Node')

function Node:initialize(id, type, position, floor_index)
  self.id = id
  self.type = type
  self.position = position or {x = 0, y = 0}
  self.completed = false
  self.floor_index = floor_index or 1
end

function Node:get_type()
  return self.type
end

function Node:get_position()
  return self.position
end

function Node:is_completed()
  return self.completed
end

function Node:mark_completed()
  self.completed = true
end

return Node
