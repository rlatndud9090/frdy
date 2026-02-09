---@class EdgeSelectHandler
---@field edges Edge[]
---@field on_select_callback function|nil
---@field edge_selector EdgeSelector|nil
---@field auto_advance_timer number|nil
---@field active boolean

local class = require('lib.middleclass')
local EdgeSelector = require('src.ui.edge_selector')

local EdgeSelectHandler = class('EdgeSelectHandler')

---Constructor
---@param edges Edge[]
---@param on_select_callback function|nil
function EdgeSelectHandler:initialize(edges, on_select_callback)
  self.edges = edges or {}
  self.on_select_callback = on_select_callback
  self.active = false

  -- Create EdgeSelector at screen center
  self.edge_selector = EdgeSelector:new(640, 360, self.edges, function(edge)
    self:_handle_selection(edge)
  end)

  -- Auto-advance for single edge
  if #self.edges == 1 then
    self.auto_advance_timer = 1.0
  else
    self.auto_advance_timer = nil
  end
end

---Activate handler
function EdgeSelectHandler:activate()
  self.active = true
end

---Deactivate handler
function EdgeSelectHandler:deactivate()
  self.active = false
end

---Reinitialize with new edges
---@param edges Edge[]
---@param on_select_callback function
function EdgeSelectHandler:setup(edges, on_select_callback)
  self.edges = edges
  self.on_select_callback = on_select_callback

  -- Recreate EdgeSelector
  self.edge_selector = EdgeSelector:new(640, 360, self.edges, function(edge)
    self:_handle_selection(edge)
  end)

  -- Reset auto-advance timer if single edge
  if #self.edges == 1 then
    self.auto_advance_timer = 1.0
  else
    self.auto_advance_timer = nil
  end
end

---Update handler
---@param dt number
function EdgeSelectHandler:update(dt)
  if not self.active then
    return
  end

  -- Handle auto-advance for single edge
  if self.auto_advance_timer then
    self.auto_advance_timer = self.auto_advance_timer - dt
    if self.auto_advance_timer <= 0 then
      self:_handle_selection(self.edges[1])
      return
    end
  end

  -- Update edge selector
  if self.edge_selector then
    self.edge_selector:update(dt)
  end
end

---Draw handler
function EdgeSelectHandler:draw()
  if not self.active then
    return
  end

  -- Draw instruction text at top center
  love.graphics.setColor(1, 1, 1, 1)
  local font = love.graphics.getFont()
  local text = "다음 경로를 선택하세요"
  local text_width = font:getWidth(text)
  love.graphics.print(text, 640 - text_width / 2, 50)

  -- Draw edge selector
  if self.edge_selector then
    self.edge_selector:draw()
  end
end

---Handle mouse press
---@param x number
---@param y number
---@param button number
function EdgeSelectHandler:mousepressed(x, y, button)
  if not self.active then
    return
  end

  if self.edge_selector then
    self.edge_selector:mousepressed(x, y, button)
  end
end

---Internal selection handler
---@param edge Edge
function EdgeSelectHandler:_handle_selection(edge)
  if self.on_select_callback then
    self.on_select_callback(edge)
  end
  self.active = false
end

return EdgeSelectHandler
