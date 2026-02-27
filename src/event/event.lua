local class = require('lib.middleclass')
local i18n = require('src.i18n.init')

---@class Event
---@field id string
---@field title string
---@field description string
---@field choices Choice[]
---@field intervention_max_mental_stage number
---@field intervention_mental_increase number
local Event = class('Event')

---@param data {id: string, title: string, description: string, choices: Choice[], intervention_max_mental_stage?: number, intervention_mental_increase?: number}
function Event:initialize(data)
  self.id = data.id
  self.title = data.title
  self.description = data.description
  self.choices = data.choices or {}
  self.intervention_max_mental_stage = data.intervention_max_mental_stage or 3
  self.intervention_mental_increase = data.intervention_mental_increase or 0.2
end

---@return string
function Event:get_id()
  return self.id
end

---@return string
function Event:get_title()
  return i18n.t(self.title)
end

---@return string
function Event:get_description()
  return i18n.t(self.description)
end

---@return Choice[]
function Event:get_choices()
  return self.choices
end

---@return number
function Event:get_choice_count()
  return #self.choices
end

---@return number
function Event:get_intervention_max_mental_stage()
  return self.intervention_max_mental_stage
end

---@return number
function Event:get_intervention_mental_increase()
  return self.intervention_mental_increase
end

return Event
