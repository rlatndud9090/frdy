local class = require("lib.middleclass")
local UIElement = require("src.ui.ui_element")
local MapUtils = require("src.ui.map_utils")
local i18n = require("src.i18n.init")

---@class Minimap : UIElement
---@field floor Floor|nil
---@field current_node Node|nil
---@field on_click_callback function|nil
---@field blink_timer number
---@field blink_on boolean
---@field padding number
local Minimap = class("Minimap", UIElement)

---@param x number
---@param y number
---@param width number
---@param height number
function Minimap:initialize(x, y, width, height)
  UIElement.initialize(self, x, y, width, height)
  self.floor = nil
  self.current_node = nil
  self.on_click_callback = nil
  self.blink_timer = 0
  self.blink_on = true
  self.padding = 10
end

---@param floor Floor
---@param current_node Node|nil
function Minimap:set_map_data(floor, current_node)
  self.floor = floor
  self.current_node = current_node
end

---@param callback function
function Minimap:set_on_click(callback)
  self.on_click_callback = callback
end

---@param dt number
function Minimap:update(dt)
  self.blink_timer = self.blink_timer + dt
  if self.blink_timer >= 0.5 then
    self.blink_timer = self.blink_timer - 0.5
    self.blink_on = not self.blink_on
  end
end

function Minimap:draw()
  if not self.visible then return end

  -- 배경
  love.graphics.setColor(0.1, 0.1, 0.15, 0.8)
  love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 4, 4)

  -- 테두리
  love.graphics.setColor(0.4, 0.4, 0.5, 0.8)
  love.graphics.rectangle("line", self.x, self.y, self.width, self.height, 4, 4)

  if not self.floor then
    love.graphics.setColor(0.6, 0.6, 0.6, 1)
    love.graphics.printf(i18n.t("ui.minimap"), self.x, self.y + self.height / 2 - 7, self.width, "center")
    return
  end

  local bounds = MapUtils.get_map_bounds(self.floor)
  if not bounds then return end

  -- 엣지 그리기
  love.graphics.setColor(0.5, 0.5, 0.5, 0.4)
  love.graphics.setLineWidth(1)
  for _, edge in ipairs(self.floor:get_edges()) do
    local from_pos = edge:get_from_node():get_position()
    local to_pos = edge:get_to_node():get_position()
    local fx, fy = MapUtils.world_to_view(from_pos.x, from_pos.y, bounds, self.x, self.y, self.width, self.height, self.padding)
    local tx, ty = MapUtils.world_to_view(to_pos.x, to_pos.y, bounds, self.x, self.y, self.width, self.height, self.padding)
    love.graphics.line(fx, fy, tx, ty)
  end

  -- 노드 그리기
  for _, node in ipairs(self.floor:get_nodes()) do
    local pos = node:get_position()
    local mx, my = MapUtils.world_to_view(pos.x, pos.y, bounds, self.x, self.y, self.width, self.height, self.padding)
    local alpha = node:is_completed() and 0.4 or 0.9

    local color, _, is_boss = MapUtils.get_node_visual(node)
    local radius = is_boss and 4 or 3
    love.graphics.setColor(color[1], color[2], color[3], alpha)

    love.graphics.circle("fill", mx, my, radius)

    -- 현재 노드 강조 (깜빡임)
    if node == self.current_node and self.blink_on then
      love.graphics.setColor(1, 1, 1, 0.9)
      love.graphics.circle("line", mx, my, radius + 2)
    end
  end

  love.graphics.setLineWidth(1)
end

---@param mx number
---@param my number
---@param button number
function Minimap:mousepressed(mx, my, button)
  if not self.visible then return end
  if button == 1 and self:hit_test(mx, my) then
    if self.on_click_callback then
      self.on_click_callback()
    end
  end
end

return Minimap
