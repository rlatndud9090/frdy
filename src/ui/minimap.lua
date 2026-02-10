local class = require("lib.middleclass")
local UIElement = require("src.ui.ui_element")

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

--- 맵 노드들의 월드 좌표 바운드 계산
---@return table|nil bounds {min_x, min_y, max_x, max_y, width, height}
function Minimap:_get_map_bounds()
  if not self.floor then return nil end
  local nodes = self.floor:get_nodes()
  if #nodes == 0 then return nil end

  local min_x, min_y = math.huge, math.huge
  local max_x, max_y = -math.huge, -math.huge

  for _, node in ipairs(nodes) do
    local pos = node:get_position()
    if pos.x < min_x then min_x = pos.x end
    if pos.y < min_y then min_y = pos.y end
    if pos.x > max_x then max_x = pos.x end
    if pos.y > max_y then max_y = pos.y end
  end

  local w = max_x - min_x
  local h = max_y - min_y
  -- 최소 크기 보장
  if w < 1 then w = 1 end
  if h < 1 then h = 100 end

  return {min_x = min_x, min_y = min_y, max_x = max_x, max_y = max_y, width = w, height = h}
end

--- 월드 좌표 → 미니맵 좌표 변환
---@param world_x number
---@param world_y number
---@param bounds table
---@return number, number
function Minimap:_world_to_minimap(world_x, world_y, bounds)
  local inner_w = self.width - self.padding * 2
  local inner_h = self.height - self.padding * 2

  local scale_x = inner_w / bounds.width
  local scale_y = inner_h / bounds.height
  local scale = math.min(scale_x, scale_y)

  -- 중앙 정렬 오프셋
  local used_w = bounds.width * scale
  local used_h = bounds.height * scale
  local offset_x = (inner_w - used_w) / 2
  local offset_y = (inner_h - used_h) / 2

  local mx = self.x + self.padding + offset_x + (world_x - bounds.min_x) * scale
  local my = self.y + self.padding + offset_y + (world_y - bounds.min_y) * scale
  return mx, my
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
    love.graphics.printf("미니맵", self.x, self.y + self.height / 2 - 7, self.width, "center")
    return
  end

  local bounds = self:_get_map_bounds()
  if not bounds then return end

  -- 엣지 그리기
  love.graphics.setColor(0.5, 0.5, 0.5, 0.4)
  love.graphics.setLineWidth(1)
  for _, edge in ipairs(self.floor.edges) do
    local from_pos = edge:get_from_node():get_position()
    local to_pos = edge:get_to_node():get_position()
    local fx, fy = self:_world_to_minimap(from_pos.x, from_pos.y, bounds)
    local tx, ty = self:_world_to_minimap(to_pos.x, to_pos.y, bounds)
    love.graphics.line(fx, fy, tx, ty)
  end

  -- 노드 그리기
  for _, node in ipairs(self.floor:get_nodes()) do
    local pos = node:get_position()
    local mx, my = self:_world_to_minimap(pos.x, pos.y, bounds)
    local node_type = node:get_type()
    local alpha = node:is_completed() and 0.4 or 0.9

    local radius = 3
    if node_type == "combat" then
      if node.is_boss and node:is_boss() then
        love.graphics.setColor(0.8, 0.1, 0.1, alpha)
        radius = 4
      else
        love.graphics.setColor(0.3, 0.3, 0.8, alpha)
      end
    elseif node_type == "event" then
      love.graphics.setColor(0.2, 0.7, 0.3, alpha)
    end

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
