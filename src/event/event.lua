local class = require('lib.middleclass')
local i18n = require('src.i18n.init')

---@class Event
---@field id string
---@field title string
---@field description string
---@field choices Choice[]
local Event = class('Event')

---@param data {id: string, title: string, description: string, choices: Choice[]}
function Event:initialize(data)
  self.id = data.id
  self.title = data.title
  self.description = data.description
  self.choices = data.choices or {}
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

return Event
