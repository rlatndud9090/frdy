local class = require("middleclass")
local UIElement = require("src.ui.ui_element")

local Gauge = class("Gauge", UIElement)

function Gauge:initialize(x, y, width, height, label)
	Gauge.__super.initialize(self, x, y, width, height)
	self.current_value = 0
	self.max_value = 100
	self.fg_color = {0, 1, 0}  -- 초록
	self.bg_color = {0.2, 0.2, 0.2}  -- 어두운 회색
	self.label = label or "Gauge"
end

function Gauge:set_value(current, max)
	self.current_value = current or 0
	if max then
		self.max_value = max
	end
end

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
	love.graphics.print(
		string.format("%s: %d/%d", self.label, self.current_value, self.max_value),
		self.x + 5,
		self.y + (self.height - 10) / 2
	)
end

return Gauge
