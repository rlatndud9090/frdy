local class = require("lib.middleclass")
local UIElement = require("src.ui.ui_element")
local i18n = require("src.i18n.init")

---@class Edge
---@field get_to_node fun(self: Edge): Node
---@field get_from_node fun(self: Edge): Node

---@class Node
---@field get_type fun(self: Node): string

---@class EdgeSelectorOption
---@field edge Edge
---@field label_key string
---@field path_style string
---@field x number
---@field y number
---@field width number
---@field height number

---@class EdgeSelector : UIElement
---@field edges Edge[]
---@field on_select_callback function|nil
---@field options EdgeSelectorOption[]
---@field anchor_x number
---@field anchor_y number
---@field selected_index number|nil
---@field hero_choice_index number|nil
---@field blink_on boolean
---@field hovered_index number|nil
---@field locked_indices table<number, boolean>
local EdgeSelector = class("EdgeSelector", UIElement)

local PATH_STYLES = {"road", "tunnel", "door"}

---@param x number
---@param y number
---@param edges Edge[]
---@param on_select_callback? function
function EdgeSelector:initialize(x, y, edges, on_select_callback)
  UIElement.initialize(self, 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
  self.edges = edges or {}
  self.on_select_callback = on_select_callback
  self.options = {}
  self.anchor_x = x
  self.anchor_y = y
  self.selected_index = nil
  self.hero_choice_index = nil
  self.blink_on = true
  self.hovered_index = nil
  self.locked_indices = {}
  self:_rebuild_options()
end

---@return nil
function EdgeSelector:_rebuild_options()
  self.options = {}
  local count = #self.edges
  if count == 0 then
    return
  end

  local spacing = 120
  local total_h = (count - 1) * spacing
  local start_y = self.anchor_y - total_h * 0.5

  for i, edge in ipairs(self.edges) do
    local to_node = edge:get_to_node()
    local node_type = to_node:get_type()

    local label_key = node_type
    if node_type == "combat" then
      if to_node.is_elite and to_node:is_elite() then
        label_key = "node.elite"
      else
        label_key = "node.combat"
      end
    elseif node_type == "event" then
      label_key = "node.event"
    end

    local option = {
      edge = edge,
      label_key = label_key,
      path_style = PATH_STYLES[((i - 1) % #PATH_STYLES) + 1],
      x = self.anchor_x + 420,
      y = start_y + (i - 1) * spacing,
      width = 140,
      height = 50,
    }
    table.insert(self.options, option)
  end
end

---@param selected_index number|nil
---@param hero_choice_index number|nil
---@param blink_on boolean
---@param locked_indices table<number, boolean>
---@return nil
function EdgeSelector:set_visual_state(selected_index, hero_choice_index, blink_on, locked_indices)
  self.selected_index = selected_index
  self.hero_choice_index = hero_choice_index
  self.blink_on = blink_on
  self.locked_indices = locked_indices or {}
end

---@param mx number
---@param my number
---@param option EdgeSelectorOption
---@return boolean
function EdgeSelector:_is_option_hit(mx, my, option)
  local left = option.x - option.width * 0.5
  local right = option.x + option.width * 0.5
  local top = option.y - option.height * 0.5
  local bottom = option.y + option.height * 0.5
  return mx >= left and mx <= right and my >= top and my <= bottom
end

---@param dt number
function EdgeSelector:update(dt)
  if not self.visible then
    return
  end

  local mx, my = love.mouse.getPosition()
  self.hovered_index = nil
  for i, option in ipairs(self.options) do
    if self:_is_option_hit(mx, my, option) then
      self.hovered_index = i
      break
    end
  end
end

---@return nil
function EdgeSelector:_draw_hero_anchor()
  love.graphics.setColor(1, 0.8, 0, 1)
  love.graphics.circle("fill", self.anchor_x, self.anchor_y, 18)
  love.graphics.setColor(1, 1, 1, 0.7)
  love.graphics.circle("line", self.anchor_x, self.anchor_y, 24)
end

---@param option EdgeSelectorOption
---@return nil
function EdgeSelector:_draw_path(option)
  local sx = self.anchor_x + 22
  local sy = self.anchor_y
  local ex = option.x - 88
  local ey = option.y

  if option.path_style == "road" then
    love.graphics.setColor(0.45, 0.33, 0.2, 0.95)
    love.graphics.setLineWidth(9)
    love.graphics.line(sx, sy, ex, ey)
    love.graphics.setColor(0.92, 0.84, 0.55, 0.45)
    love.graphics.setLineWidth(2)
    love.graphics.line((sx + ex) * 0.5 - 16, (sy + ey) * 0.5, (sx + ex) * 0.5 + 16, (sy + ey) * 0.5)
  elseif option.path_style == "tunnel" then
    love.graphics.setColor(0.2, 0.2, 0.24, 1)
    love.graphics.setLineWidth(13)
    love.graphics.line(sx, sy, ex, ey)
    love.graphics.setColor(0.45, 0.45, 0.5, 0.7)
    love.graphics.setLineWidth(1.5)
    love.graphics.line(sx, sy - 8, ex, ey - 8)
    love.graphics.line(sx, sy + 8, ex, ey + 8)
  else
    love.graphics.setColor(0.52, 0.42, 0.28, 0.9)
    love.graphics.setLineWidth(7)
    love.graphics.line(sx, sy, ex, ey)
    love.graphics.setColor(0.36, 0.24, 0.14, 1)
    love.graphics.rectangle("fill", ex - 14, ey - 26, 22, 52, 3, 3)
    love.graphics.setColor(0.78, 0.62, 0.36, 1)
    love.graphics.rectangle("line", ex - 14, ey - 26, 22, 52, 3, 3)
  end
end

---@param option EdgeSelectorOption
---@param index number
---@return nil
function EdgeSelector:_draw_option_arrow(option, index)
  local is_hovered = self.hovered_index == index
  local is_selected = self.selected_index == index
  local is_hero_choice = self.hero_choice_index == index and self.blink_on
  local is_locked = self.locked_indices[index] == true

  local fill = {0.24, 0.26, 0.3, 0.95}
  local border = {0.8, 0.82, 0.9, 0.8}
  if is_locked then
    fill = {0.2, 0.2, 0.2, 0.85}
    border = {0.45, 0.45, 0.45, 0.9}
  elseif is_selected and is_hero_choice then
    fill = {0.72, 0.52, 0.14, 1}
    border = {1, 0.95, 0.65, 1}
  elseif is_selected then
    fill = {0.2, 0.45, 0.72, 1}
    border = {0.72, 0.88, 1, 1}
  elseif is_hero_choice then
    fill = {0.56, 0.42, 0.1, 0.95}
    border = {1, 0.85, 0.4, 1}
  elseif is_hovered then
    fill = {0.32, 0.34, 0.4, 1}
  end

  local x = option.x
  local y = option.y
  local w = option.width
  local h = option.height
  local left = x - w * 0.5
  local right = x + w * 0.5
  local tip_x = right + 22

  love.graphics.setColor(fill)
  love.graphics.polygon("fill",
    left, y - h * 0.5,
    right - 12, y - h * 0.5,
    tip_x, y,
    right - 12, y + h * 0.5,
    left, y + h * 0.5)

  love.graphics.setColor(border)
  love.graphics.setLineWidth(2)
  love.graphics.polygon("line",
    left, y - h * 0.5,
    right - 12, y - h * 0.5,
    tip_x, y,
    right - 12, y + h * 0.5,
    left, y + h * 0.5)

  love.graphics.setColor(1, 1, 1, is_locked and 0.5 or 1)
  local label = i18n.t(option.label_key)
  local text_w = love.graphics.getFont():getWidth(label)
  local text_h = love.graphics.getFont():getHeight()
  love.graphics.print(label, x - text_w * 0.5, y - text_h * 0.5)
end

function EdgeSelector:draw()
  if not self.visible then
    return
  end

  self:_draw_hero_anchor()
  for i, option in ipairs(self.options) do
    self:_draw_path(option)
    self:_draw_option_arrow(option, i)
  end
  love.graphics.setLineWidth(1)
end

---@param mx number
---@param my number
---@param button number
function EdgeSelector:mousepressed(mx, my, button)
  if not self.visible or button ~= 1 then
    return
  end

  for i, option in ipairs(self.options) do
    if self:_is_option_hit(mx, my, option) then
      if self.on_select_callback then
        self.on_select_callback(option.edge, i)
      end
      return
    end
  end
end

return EdgeSelector
