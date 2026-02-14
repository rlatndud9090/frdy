---@class StartNodeSelectHandler
---@field nodes Node[]
---@field on_select_callback function|nil
---@field selector StartNodeSelector|nil
---@field active boolean

local class = require("lib.middleclass")
local StartNodeSelector = require("src.ui.start_node_selector")

local StartNodeSelectHandler = class("StartNodeSelectHandler")

---@param nodes Node[]
---@param on_select_callback function|nil
---@return nil
function StartNodeSelectHandler:initialize(nodes, on_select_callback)
  self.nodes = nodes or {}
  self.on_select_callback = on_select_callback
  self.active = false
  self.selector = StartNodeSelector:new(530, 250, self.nodes, function(node)
    self:_handle_selection(node)
  end)
end

---@param nodes Node[]
---@param on_select_callback function|nil
---@return nil
function StartNodeSelectHandler:setup(nodes, on_select_callback)
  self.nodes = nodes or {}
  self.on_select_callback = on_select_callback
  self.selector = StartNodeSelector:new(530, 250, self.nodes, function(node)
    self:_handle_selection(node)
  end)
end

---@return nil
function StartNodeSelectHandler:activate()
  self.active = true
end

---@return nil
function StartNodeSelectHandler:deactivate()
  self.active = false
end

---@param dt number
---@return nil
function StartNodeSelectHandler:update(dt)
  if not self.active then
    return
  end

  if self.selector then
    self.selector:update(dt)
  end
end

---@return nil
function StartNodeSelectHandler:draw()
  if not self.active then
    return
  end

  love.graphics.setColor(1, 1, 1, 1)
  local font = love.graphics.getFont()
  local text = "Select your starting path"
  local text_width = font:getWidth(text)
  love.graphics.print(text, 640 - text_width / 2, 200)

  if self.selector then
    self.selector:draw()
  end
end

---@param x number
---@param y number
---@param button number
---@return nil
function StartNodeSelectHandler:mousepressed(x, y, button)
  if not self.active then
    return
  end

  if self.selector then
    self.selector:mousepressed(x, y, button)
  end
end

---@param node Node
---@return nil
function StartNodeSelectHandler:_handle_selection(node)
  if self.on_select_callback then
    self.on_select_callback(node)
  end
  self.active = false
end

return StartNodeSelectHandler
