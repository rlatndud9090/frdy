local class = require("lib.middleclass")
local UIElement = require("src.ui.ui_element")

---@class Panel : UIElement
---@field children UIElement[]
---@field background_color number[]|nil
local Panel = class("Panel", UIElement)

---@param x number
---@param y number
---@param width number
---@param height number
---@param background_color? number[]
function Panel:initialize(x, y, width, height, background_color)
	UIElement.initialize(self, x, y, width, height)
	self.children = {}
	self.background_color = background_color or nil
end

---@param child UIElement
function Panel:add_child(child)
	table.insert(self.children, child)
	child.parent = self
end

---@param child UIElement
function Panel:remove_child(child)
	for i, c in ipairs(self.children) do
		if c == child then
			table.remove(self.children, i)
			child.parent = nil
			break
		end
	end
end

---@param dt number
function Panel:update(dt)
	for _, child in ipairs(self.children) do
		if child.visible then
			child:update(dt)
		end
	end
end

function Panel:draw()
	if not self.visible then
		return
	end

	-- 배경 그리기
	if self.background_color then
		love.graphics.setColor(self.background_color)
		love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
		love.graphics.setColor(1, 1, 1, 1)
	end

	-- 자식 요소들 그리기
	for _, child in ipairs(self.children) do
		if child.visible then
			child:draw()
		end
	end
end

---@param mx number
---@param my number
---@param button number
function Panel:mousepressed(mx, my, button)
	if not self.visible then
		return
	end

	-- 자식 요소들에게 마우스 이벤트 전파
	for _, child in ipairs(self.children) do
		if child.visible and child:hit_test(mx, my) then
			if child.mousepressed then
				child:mousepressed(mx, my, button)
			end
		end
	end
end

return Panel
