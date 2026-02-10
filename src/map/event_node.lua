local Node = require('src.map.node')

---@class EventNode : Node
---@field event_id string|nil
local EventNode = Node:subclass('EventNode')

---@param id number
---@param position {x: number, y: number}
---@param floor_index number
---@param event_id? string
function EventNode:initialize(id, position, floor_index, event_id)
  Node.initialize(self, id, "event", position, floor_index)
  self.event_id = event_id
end

---@return string|nil
function EventNode:get_event_id()
  return self.event_id
end

return EventNode
