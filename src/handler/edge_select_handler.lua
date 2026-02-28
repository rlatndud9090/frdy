---@class Edge
---@field get_to_node fun(self: Edge): Node

---@class Node
---@field get_type fun(self: Node): string

---@class Hero
---@field get_mental_stage fun(self: Hero): number
---@field can_be_controlled fun(self: Hero, max_stage: number): boolean
---@field increase_mental_load fun(self: Hero, amount: number): number
---@field get_max_mental_stage fun(self: Hero): number

---@class EdgeSelectContext
---@field hero Hero|nil

---@class EdgeSelectHandler
---@field edges Edge[]
---@field on_select_callback function|nil
---@field edge_selector EdgeSelector|nil
---@field confirm_button Button
---@field active boolean
---@field hero Hero|nil
---@field hero_choice_index number|nil
---@field selected_index number|nil
---@field locked_indices table<number, boolean>
---@field blink_timer number
---@field blink_on boolean
---@field feedback_text string|nil
---@field path_control table

local class = require('lib.middleclass')
local EdgeSelector = require('src.ui.edge_selector')
local Button = require('src.ui.button')
local i18n = require('src.i18n.init')
local path_control = require('data.interventions.path_control')

local EdgeSelectHandler = class('EdgeSelectHandler')

local BLINK_INTERVAL = 0.45

---Constructor
---@param edges Edge[]
---@param on_select_callback function|nil
---@param context? EdgeSelectContext
function EdgeSelectHandler:initialize(edges, on_select_callback, context)
  self.edges = edges or {}
  self.on_select_callback = on_select_callback
  self.edge_selector = nil
  self.confirm_button = Button:new(1040, 640, 180, 46, "ui.confirm")
  self.confirm_button:set_on_click(function()
    self:_confirm_selection()
  end)
  self.active = false
  self.hero = nil
  self.hero_choice_index = nil
  self.selected_index = nil
  self.locked_indices = {}
  self.blink_timer = 0
  self.blink_on = true
  self.feedback_text = nil
  self.path_control = path_control
  self:setup(self.edges, self.on_select_callback, context)
end

---Activate handler
---@return nil
function EdgeSelectHandler:activate()
  self.active = true
end

---Deactivate handler
---@return nil
function EdgeSelectHandler:deactivate()
  self.active = false
end

---@return number|nil
function EdgeSelectHandler:_roll_hero_choice_index()
  if #self.edges == 0 then
    return nil
  end
  return math.random(#self.edges)
end

---@return boolean
function EdgeSelectHandler:_can_intervene()
  if not self.hero then
    return false
  end
  local max_stage = self.path_control.max_mental_stage or 0
  return self.hero:can_be_controlled(max_stage)
end

---@return nil
function EdgeSelectHandler:_refresh_locked_indices()
  self.locked_indices = {}
  if self:_can_intervene() then
    return
  end

  for i = 1, #self.edges do
    if i ~= self.hero_choice_index then
      self.locked_indices[i] = true
    end
  end
end

---@return string
function EdgeSelectHandler:_format_mental_text()
  if not self.hero then
    return i18n.t("ui.mental_stage", {stage = "?", max = 5})
  end
  return i18n.t("ui.mental_stage", {
    stage = self.hero:get_mental_stage(),
    max = self.hero:get_max_mental_stage(),
  })
end

---@param edge Edge
---@return string
function EdgeSelectHandler:_edge_label(edge)
  local node_type = edge:get_to_node():get_type()
  if node_type == "combat" then
    return i18n.t("node.combat")
  elseif node_type == "event" then
    return i18n.t("node.event")
  end
  return node_type
end

---@return nil
function EdgeSelectHandler:_apply_intervention()
  if not self.hero_choice_index or not self.selected_index then
    return
  end
  if self.hero_choice_index == self.selected_index then
    return
  end
  if not self.hero then
    return
  end

  self.hero:increase_mental_load(self.path_control.mental_increase or 0)
end

---Reinitialize with new edges
---@param edges Edge[]
---@param on_select_callback function
---@param context? EdgeSelectContext
---@return nil
function EdgeSelectHandler:setup(edges, on_select_callback, context)
  self.edges = edges or {}
  self.on_select_callback = on_select_callback
  self.hero = context and context.hero or nil

  self.hero_choice_index = self:_roll_hero_choice_index()
  self.selected_index = self.hero_choice_index
  self.blink_timer = 0
  self.blink_on = true
  self.feedback_text = nil
  self:_refresh_locked_indices()

  self.edge_selector = EdgeSelector:new(260, 360, self.edges, function(edge, index)
    self:_on_edge_clicked(edge, index)
  end)
end

---Update handler
---@param dt number
---@return nil
function EdgeSelectHandler:update(dt)
  if not self.active then
    return
  end

  self.blink_timer = self.blink_timer + dt
  if self.blink_timer >= BLINK_INTERVAL then
    self.blink_timer = self.blink_timer - BLINK_INTERVAL
    self.blink_on = not self.blink_on
  end

  self:_refresh_locked_indices()
  if self.edge_selector then
    self.edge_selector:set_visual_state(self.selected_index, self.hero_choice_index, self.blink_on, self.locked_indices)
    self.edge_selector:update(dt)
  end
  self.confirm_button:update(dt)
end

---Draw handler
---@return nil
function EdgeSelectHandler:draw()
  if not self.active then
    return
  end

  love.graphics.setColor(1, 1, 1, 1)
  local font = love.graphics.getFont()

  local title = i18n.t("ui.select_next_path")
  local title_width = font:getWidth(title)
  love.graphics.print(title, 640 - title_width / 2, 44)

  love.graphics.setColor(0.88, 0.88, 0.95, 1)
  love.graphics.print(i18n.t("ui.path_prediction_hint"), 50, 88)
  love.graphics.print(self:_format_mental_text(), 50, 112)

  if self.hero_choice_index and self.edges[self.hero_choice_index] then
    local predicted_label = self:_edge_label(self.edges[self.hero_choice_index])
    love.graphics.setColor(1, 0.86, 0.4, 1)
    love.graphics.print(i18n.t("ui.hero_predicted_path", {label = predicted_label}), 50, 136)
  end

  if self.feedback_text then
    love.graphics.setColor(0.96, 0.56, 0.56, 1)
    love.graphics.print(self.feedback_text, 50, 162)
  end

  if self.edge_selector then
    self.edge_selector:draw()
  end
  self.confirm_button:draw()
end

---@param edge Edge
---@param index number
---@return nil
function EdgeSelectHandler:_on_edge_clicked(edge, index)
  if index == self.selected_index then
    return
  end

  if index == self.hero_choice_index then
    self.selected_index = index
    self.feedback_text = i18n.t("control.selection_reset")
    return
  end

  if not self:_can_intervene() then
    local hero_stage = self.hero and self.hero:get_mental_stage() or 0
    local max_stage = self.path_control.max_mental_stage or 0
    self.feedback_text = i18n.t("control.blocked_by_mental", {stage = hero_stage, max = max_stage})
    return
  end

  self.selected_index = index
  self.feedback_text = i18n.t("control.path_intervened")
end

---@return nil
function EdgeSelectHandler:_confirm_selection()
  if not self.selected_index then
    return
  end

  self:_apply_intervention()

  local selected_edge = self.edges[self.selected_index]
  if selected_edge and self.on_select_callback then
    self.on_select_callback(selected_edge)
  end
  self.active = false
end

---Handle mouse press
---@param x number
---@param y number
---@param button number
---@return nil
function EdgeSelectHandler:mousepressed(x, y, button)
  if not self.active then
    return
  end

  if button == 1 and self.confirm_button:hit_test(x, y) then
    self.confirm_button:mousepressed(x, y, button)
    return
  end

  if self.edge_selector then
    self.edge_selector:mousepressed(x, y, button)
  end
end

return EdgeSelectHandler
