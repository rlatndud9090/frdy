local class = require("lib.middleclass")
local UIElement = require("src.ui.ui_element")
local i18n = require("src.i18n.init")

---@class Gauge : UIElement
---@field current_value number
---@field max_value number
---@field fg_color number[]
---@field bg_color number[]
---@field label string
local Gauge = class("Gauge", UIElement)

---@param x number
---@param y number
---@param width number
---@param height number
---@param label? string
---@param fg_color? number[]
function Gauge:initialize(x, y, width, height, label, fg_color)
	UIElement.initialize(self, x, y, width, height)
	self.current_value = 0
	self.max_value = 100
	self.fg_color = fg_color or {0, 1, 0}  -- 기본값 초록색
	self.bg_color = {0.2, 0.2, 0.2}  -- 어두운 회색
	self.label = label or "Gauge"
end

---@param current? number
---@param max? number
function Gauge:set_value(current, max)
	self.current_value = current or 0
	if max then
		self.max_value = max
	end
end

---@param max? number
function Gauge:set_max(max)
	self.max_value = max or 100
end

function Gauge:draw()
	if not self.visible then
		return
	end

	-- 배경 사각형 그리기
	love.graphics.setColor(self.bg_color)
	love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)

	-- 현재값 비율만큼 채워진 사각형 그리기
	local fill_width = (self.current_value / self.max_value) * self.width
	love.graphics.setColor(self.fg_color)
	love.graphics.rectangle("fill", self.x, self.y, fill_width, self.height)

	-- 라벨 텍스트 표시
	love.graphics.setColor({1, 1, 1})  -- 흰색
	local display_label = i18n.t(self.label)
	love.graphics.print(
		string.format("%s: %d/%d", display_label, self.current_value, self.max_value),
		self.x + 5,
		self.y + (self.height - 10) / 2
	)
end

return Gauge
