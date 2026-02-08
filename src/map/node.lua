local class = require('lib.middleclass')

---@class Node
---@field id number
---@field type string
---@field position {x: number, y: number}
---@field completed boolean
---@field floor_index number
local Node = class('Node')

---@param id number
---@param type string
---@param position? {x: number, y: number}
---@param floor_index? number
function Node:initialize(id, type, position, floor_index)
  self.id = id
  self.type = type
  self.position = position or {x = 0, y = 0}
  self.completed = false
  self.floor_index = floor_index or 1
end

---@return string
function Node:get_type()
  return self.type
end

---@return {x: number, y: number}
function Node:get_position()
  return self.position
end

---@return boolean
function Node:is_completed()
  return self.completed
end

function Node:mark_completed()
  self.completed = true
end

return Node
