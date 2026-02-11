local class = require("lib.middleclass")
local UIElement = require("src.ui.ui_element")
local i18n = require("src.i18n.init")

---@class Button : UIElement
---@field text string
---@field callback function|nil
---@field bg_color number[]
---@field hover_color number[]
---@field text_color number[]
---@field is_hovered boolean
local Button = class("Button", UIElement)

---@param x number
---@param y number
---@param width number
---@param height number
---@param text? string
---@param callback? function
function Button:initialize(x, y, width, height, text, callback)
	UIElement.initialize(self, x, y, width, height)
	self.text = text or ""
	self.callback = callback
	self.bg_color = {0.3, 0.3, 0.3}
	self.hover_color = {0.5, 0.5, 0.5}
	self.text_color = {1, 1, 1}
	self.is_hovered = false
end

---@param dt number
function Button:update(dt)
	if self.visible then
		local mx, my = love.mouse.getPosition()
		self.is_hovered = self:hit_test(mx, my)
	end
end

function Button:draw()
	if not self.visible then return end

	-- 배경 사각형
	local color = self.is_hovered and self.hover_color or self.bg_color
	love.graphics.setColor(color)
	love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)

	-- 테두리
	love.graphics.setColor({1, 1, 1})
	love.graphics.rectangle("line", self.x, self.y, self.width, self.height)

	-- 텍스트 중앙 표시
	love.graphics.setColor(self.text_color)
	local display_text = i18n.t(self.text)
	local text_width = love.graphics.getFont():getWidth(display_text)
	local text_height = love.graphics.getFont():getHeight()
	local text_x = self.x + (self.width - text_width) / 2
	local text_y = self.y + (self.height - text_height) / 2
	love.graphics.print(display_text, text_x, text_y)
end

---@param callback function|nil
function Button:set_on_click(callback)
	self.callback = callback
end

function Button:on_click()
	if self.callback then
		self.callback()
	end
end

---@param mx number
---@param my number
---@param button number
function Button:mousepressed(mx, my, button)
	if button == 1 and self.visible and self:hit_test(mx, my) then
		self:on_click()
	end
end

return Button
