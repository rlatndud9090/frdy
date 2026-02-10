local class = require('lib.middleclass')
local Event = require('src.event.event')
local Choice = require('src.event.choice')

---@class EventManager
---@field events table<string, Event>
---@field event_list Event[]
local EventManager = class('EventManager')

function EventManager:initialize()
  self.events = {}
  self.event_list = {}
end

---@param data_table table[]
function EventManager:load_events(data_table)
  for _, event_data in ipairs(data_table) do
    local choices = {}
    for _, choice_data in ipairs(event_data.choices or {}) do
      table.insert(choices, Choice:new(choice_data))
    end

    local event = Event:new({
      id = event_data.id,
      title = event_data.title,
      description = event_data.description,
      choices = choices,
    })

    self.events[event_data.id] = event
    table.insert(self.event_list, event)
  end
end

---@param id string
---@return Event|nil
function EventManager:get_event(id)
  return self.events[id]
end

---@return Event|nil
function EventManager:get_random_event()
  if #self.event_list == 0 then return nil end
  return self.event_list[math.random(#self.event_list)]
end

---@return number
function EventManager:get_event_count()
  return #self.event_list
end

return EventManager
