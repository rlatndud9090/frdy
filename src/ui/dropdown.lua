local class = require("lib.middleclass")
local UIElement = require("src.ui.ui_element")

---@class Dropdown : UIElement
---@field options table[] -- {key, label}
---@field selected_index number
---@field is_open boolean
---@field on_change function|nil -- function(key, label)
---@field option_height number
local Dropdown = class("Dropdown", UIElement)

---@param x number
---@param y number
---@param width number
---@param height number
---@param options table[] -- {{key="en", label="English"}, ...}
---@param selected_key string|nil
function Dropdown:initialize(x, y, width, height, options, selected_key)
  UIElement.initialize(self, x, y, width, height)
  self.options = options or {}
  self.is_open = false
  self.on_change = nil
  self.option_height = height
  self.selected_index = 1

  if selected_key then
    for i, opt in ipairs(self.options) do
      if opt.key == selected_key then
        self.selected_index = i
        break
      end
    end
  end
end

---@param options table[]
---@param selected_key string|nil
function Dropdown:set_options(options, selected_key)
  self.options = options or {}
  self.selected_index = 1
  if selected_key then
    for i, opt in ipairs(self.options) do
      if opt.key == selected_key then
        self.selected_index = i
        break
      end
    end
  end
end

---@param callback function
function Dropdown:set_on_change(callback)
  self.on_change = callback
end

---@return table|nil {key, label}
function Dropdown:get_selected()
  return self.options[self.selected_index]
end

function Dropdown:update(dt)
  -- no-op
end

function Dropdown:draw()
  if not self.visible then return end

  -- Selected item box
  local hovered_main = self:_hit_test_main()
  if hovered_main then
    love.graphics.setColor(0.35, 0.35, 0.45, 1)
  else
    love.graphics.setColor(0.25, 0.25, 0.35, 1)
  end
  love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 4, 4)

  love.graphics.setColor(0.6, 0.6, 0.7, 1)
  love.graphics.rectangle("line", self.x, self.y, self.width, self.height, 4, 4)

  -- Selected text
  love.graphics.setColor(1, 1, 1, 1)
  local selected = self.options[self.selected_index]
  local label = selected and selected.label or ""
  local font = love.graphics.getFont()
  local text_y = self.y + (self.height - font:getHeight()) / 2
  love.graphics.print(label, self.x + 10, text_y)

  -- Arrow indicator
  local arrow = self.is_open and "^" or "v"
  local arrow_x = self.x + self.width - 20
  love.graphics.print(arrow, arrow_x, text_y)

  -- Dropdown list
  if self.is_open then
    local list_y = self.y + self.height
    for i, opt in ipairs(self.options) do
      local oy = list_y + (i - 1) * self.option_height
      local hovered = self:_hit_test_option(i)

      if i == self.selected_index then
        love.graphics.setColor(0.3, 0.4, 0.6, 1)
      elseif hovered then
        love.graphics.setColor(0.35, 0.35, 0.45, 1)
      else
        love.graphics.setColor(0.2, 0.2, 0.3, 0.95)
      end
      love.graphics.rectangle("fill", self.x, oy, self.width, self.option_height)

      love.graphics.setColor(0.5, 0.5, 0.6, 1)
      love.graphics.rectangle("line", self.x, oy, self.width, self.option_height)

      love.graphics.setColor(1, 1, 1, 1)
      local opt_text_y = oy + (self.option_height - font:getHeight()) / 2
      love.graphics.print(opt.label, self.x + 10, opt_text_y)
    end
  end
end

---@param mx number
---@param my number
---@param button number
function Dropdown:mousepressed(mx, my, button)
  if not self.visible or button ~= 1 then return end

  if self.is_open then
    -- Check option clicks
    for i = 1, #self.options do
      if self:_hit_test_option(i, mx, my) then
        self.selected_index = i
        self.is_open = false
        if self.on_change then
          local opt = self.options[i]
          self.on_change(opt.key, opt.label)
        end
        return
      end
    end
    -- Click outside closes
    self.is_open = false
  else
    if self:_hit_test_main(mx, my) then
      self.is_open = true
    end
  end
end

---@return boolean
function Dropdown:_hit_test_main(mx, my)
  if not mx then
    mx, my = love.mouse.getPosition()
  end
  return mx >= self.x and mx <= self.x + self.width
    and my >= self.y and my <= self.y + self.height
end

---@param index number
---@return boolean
function Dropdown:_hit_test_option(index, mx, my)
  if not mx then
    mx, my = love.mouse.getPosition()
  end
  local oy = self.y + self.height + (index - 1) * self.option_height
  return mx >= self.x and mx <= self.x + self.width
    and my >= oy and my <= oy + self.option_height
end

return Dropdown
