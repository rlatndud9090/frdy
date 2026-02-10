local class = require('lib.middleclass')

---@class ActionQueue
---@field queue table[]
local ActionQueue = class('ActionQueue')

function ActionQueue:initialize()
  self.queue = {}
end

---@param action {type: string, source: Entity, target: Entity, amount: number, callback: function|nil}
function ActionQueue:enqueue(action)
  self.queue[#self.queue + 1] = action
end

---@return {type: string, source: Entity, target: Entity, amount: number, callback: function|nil}|nil
function ActionQueue:process_next()
  if #self.queue == 0 then
    return nil
  end
  local action = table.remove(self.queue, 1)
  if action.callback then
    action.callback(action)
  end
  return action
end

---@return {type: string, source: Entity, target: Entity, amount: number, callback: function|nil}|nil
function ActionQueue:peek()
  return self.queue[1]
end

---@return boolean
function ActionQueue:is_empty()
  return #self.queue == 0
end

function ActionQueue:clear()
  self.queue = {}
end

return ActionQueue
