local class = require("lib.middleclass")
local UIElement = require("src.ui.ui_element")
local Button = require("src.ui.button")

---@class Edge
---@field get_to_node fun(self: Edge): Node

---@class Node
---@field get_type fun(self: Node): string

---@class EdgeSelector : UIElement
---@field edges Edge[]
---@field on_select_callback function|nil
---@field buttons Button[]
local EdgeSelector = class("EdgeSelector", UIElement)

---@param x number
---@param y number
---@param edges Edge[]
---@param on_select_callback? function
function EdgeSelector:initialize(x, y, edges, on_select_callback)
	UIElement.initialize(self, x, y, 0, 0)
	self.edges = edges or {}
	self.on_select_callback = on_select_callback
	self.buttons = {}

	-- 각 edge에 대해 버튼 생성
	local button_width = 150
	local button_height = 40
	local button_spacing = 10
	local current_y = y

	for i, edge in ipairs(self.edges) do
		local to_node = edge:get_to_node()
		local node_type = to_node:get_type()

		-- 버튼 텍스트: edge의 to_node 타입 표시
		local button_text = ""
		if node_type == "combat" then
			button_text = "node.combat"
		elseif node_type == "event" then
			button_text = "node.event"
		else
			button_text = node_type
		end

		-- 버튼 클릭 콜백
		local edge_ref = edge
		local callback = function()
			if self.on_select_callback then
				self.on_select_callback(edge_ref)
			end
		end

		-- 버튼 생성
		local button = Button(x, current_y, button_width, button_height, button_text, callback)
		table.insert(self.buttons, button)

		current_y = current_y + button_height + button_spacing
	end

	-- EdgeSelector의 크기 설정
	self.width = button_width
	self.height = current_y - y
end

---@param dt number
function EdgeSelector:update(dt)
	if not self.visible then return end

	for _, button in ipairs(self.buttons) do
		button:update(dt)
	end
end

function EdgeSelector:draw()
	if not self.visible then return end

	for _, button in ipairs(self.buttons) do
		button:draw()
	end
end

---@param mx number
---@param my number
---@param button number
function EdgeSelector:mousepressed(mx, my, button)
	if not self.visible then return end

	for _, btn in ipairs(self.buttons) do
		btn:mousepressed(mx, my, button)
	end
end

return EdgeSelector
