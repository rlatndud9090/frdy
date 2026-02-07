local Node = require('src.map.node')

local EventNode = Node:subclass('EventNode')

function EventNode:initialize(id, position, floor_index, event_id)
  Node.initialize(self, id, "event", position, floor_index)
  self.event_id = event_id
end

return EventNode
