local class = require("lib.middleclass")

local UIElement = class("UIElement")

function UIElement:initialize(x, y, width, height)
	self.x = x or 0
	self.y = y or 0
	self.width = width or 0
	self.height = height or 0
	self.visible = true
	self.parent = nil
end

function UIElement:update(dt)
	-- 서브클래스에서 오버라이드
end

function UIElement:draw()
	-- 서브클래스에서 오버라이드
end

function UIElement:hit_test(mx, my)
	return mx >= self.x and mx <= self.x + self.width and
		   my >= self.y and my <= self.y + self.height
end

function UIElement:set_position(x, y)
	self.x = x
	self.y = y
end

function UIElement:set_visible(visible)
	self.visible = visible
end

return UIElement
