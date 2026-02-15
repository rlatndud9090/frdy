local class = require("lib.middleclass")
local UIElement = require("src.ui.ui_element")
local Button = require("src.ui.button")

---@class StartNodeSelector : UIElement
---@field nodes Node[]
---@field on_select_callback function|nil
---@field buttons Button[]
local StartNodeSelector = class("StartNodeSelector", UIElement)

---@param x number
---@param y number
---@param nodes Node[]
---@param on_select_callback? function
function StartNodeSelector:initialize(x, y, nodes, on_select_callback)
  UIElement.initialize(self, x, y, 0, 0)
  self.nodes = nodes or {}
  self.on_select_callback = on_select_callback
  self.buttons = {}

  local button_width = 220
  local button_height = 40
  local button_spacing = 10
  local current_y = y

  for i, node in ipairs(self.nodes) do
    local button_text = string.format("Start Path %d", i)
    local node_ref = node
    local callback = function()
      if self.on_select_callback then
        self.on_select_callback(node_ref)
      end
    end

    local button = Button:new(x, current_y, button_width, button_height, button_text, callback)
    table.insert(self.buttons, button)
    current_y = current_y + button_height + button_spacing
  end

  self.width = button_width
  self.height = current_y - y
end

---@param dt number
---@return nil
function StartNodeSelector:update(dt)
  if not self.visible then
    return
  end

  for _, button in ipairs(self.buttons) do
    button:update(dt)
  end
end

---@return nil
function StartNodeSelector:draw()
  if not self.visible then
    return
  end

  for _, button in ipairs(self.buttons) do
    button:draw()
  end
end

---@param mx number
---@param my number
---@param button number
---@return nil
function StartNodeSelector:mousepressed(mx, my, button)
  if not self.visible then
    return
  end

  for _, btn in ipairs(self.buttons) do
    btn:mousepressed(mx, my, button)
  end
end

return StartNodeSelector
