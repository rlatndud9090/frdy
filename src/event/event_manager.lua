local class = require('lib.middleclass')
local Event = require('src.event.event')
local Choice = require('src.event.choice')
local RNG = require('src.core.rng')

---@class EventManager
---@field events table<string, Event>
---@field event_list Event[]
---@field rng RNG
local EventManager = class('EventManager')

---@param rng? RNG
---@return nil
function EventManager:initialize(rng)
  self.events = {}
  self.event_list = {}
  self.rng = rng or RNG:new(os.time())
end

---@param rng RNG
---@return nil
function EventManager:set_rng(rng)
  self.rng = rng
end

---@param data_table table[]
function EventManager:load_events(data_table)
  self.events = {}
  self.event_list = {}

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
      intervention_max_mental_stage = event_data.intervention and event_data.intervention.max_mental_stage or 3,
      intervention_mental_increase = event_data.intervention and event_data.intervention.mental_increase or 0.2,
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
  local index = self.rng:next_int(1, #self.event_list)
  return self.event_list[index]
end

---@return number
function EventManager:get_event_count()
  return #self.event_list
end

return EventManager
