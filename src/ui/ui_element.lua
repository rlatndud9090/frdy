local class = require("lib.middleclass")

---@class UIElement
---@field x number
---@field y number
---@field width number
---@field height number
---@field visible boolean
---@field parent UIElement|nil
local UIElement = class("UIElement")

---@param x? number
---@param y? number
---@param width? number
---@param height? number
function UIElement:initialize(x, y, width, height)
	self.x = x or 0
	self.y = y or 0
	self.width = width or 0
	self.height = height or 0
	self.visible = true
	self.parent = nil
end

---@param dt number
function UIElement:update(dt)
	-- 서브클래스에서 오버라이드
end

function UIElement:draw()
	-- 서브클래스에서 오버라이드
end

---@param mx number
---@param my number
---@return boolean
function UIElement:hit_test(mx, my)
	return mx >= self.x and mx <= self.x + self.width and
		   my >= self.y and my <= self.y + self.height
end

---@param x number
---@param y number
function UIElement:set_position(x, y)
	self.x = x
	self.y = y
end

---@param visible boolean
function UIElement:set_visible(visible)
	self.visible = visible
end

---@param x number
---@param y number
---@param button number
function UIElement:mousepressed(x, y, button)
	-- 서브클래스에서 오버라이드 (기본 구현은 아무것도 하지 않음)
end

return UIElement
