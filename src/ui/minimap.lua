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
---@field padding_x number
---@field padding_y number
---@field visible_column_count number
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
  self.padding_x = 6
  self.padding_y = 8
  self.visible_column_count = 5
end

---@param world_x number
---@param world_y number
---@param bounds table
---@return number
---@return number
function Minimap:_world_to_minimap(world_x, world_y, bounds)
  local inner_w = math.max(1, self.width - self.padding_x * 2)
  local inner_h = math.max(1, self.height - self.padding_y * 2)
  local nx = (world_x - bounds.min_x) / math.max(1, bounds.width)
  local ny = (world_y - bounds.min_y) / math.max(1, bounds.height)
  local sx = self.x + self.padding_x + nx * inner_w
  local sy = self.y + self.padding_y + ny * inner_h
  return sx, sy
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

---@return number[]
function Minimap:_collect_column_positions()
  local positions = {}
  local seen = {}
  for _, node in ipairs(self.floor:get_nodes()) do
    local x = node:get_position().x
    if not seen[x] then
      seen[x] = true
      table.insert(positions, x)
    end
  end
  table.sort(positions)
  return positions
end

---@param column_positions number[]
---@return number
function Minimap:_resolve_current_column_index(column_positions)
  if #column_positions == 0 then
    return 1
  end
  if not self.current_node then
    return 1
  end

  local current_x = self.current_node:get_position().x
  local best_idx = 1
  local best_diff = math.huge
  for idx, x in ipairs(column_positions) do
    local diff = math.abs(x - current_x)
    if diff < best_diff then
      best_diff = diff
      best_idx = idx
    end
  end

  return best_idx
end

---@param column_positions number[]
---@param start_idx number
---@return number, number
function Minimap:_resolve_visible_range(column_positions, start_idx)
  local clamped_start = math.max(1, math.min(start_idx, #column_positions))
  local end_idx = math.min(clamped_start + self.visible_column_count - 1, #column_positions)
  return clamped_start, end_idx
end

---@param column_positions number[]
---@param start_idx number
---@param end_idx number
---@return table<number, boolean>
function Minimap:_build_visible_column_set(column_positions, start_idx, end_idx)
  local visible_set = {}
  for idx = start_idx, end_idx do
    visible_set[column_positions[idx]] = true
  end
  return visible_set
end

---@param visible_column_set table<number, boolean>
---@return Node[]
function Minimap:_collect_visible_nodes(visible_column_set)
  local result = {}
  for _, node in ipairs(self.floor:get_nodes()) do
    local x = node:get_position().x
    if visible_column_set[x] then
      table.insert(result, node)
    end
  end
  return result
end

---@param map_bounds table
---@param column_positions number[]
---@param start_idx number
---@param end_idx number
---@return table
function Minimap:_build_window_bounds(map_bounds, column_positions, start_idx, end_idx)
  local window_min_x = column_positions[start_idx]
  local window_max_x = column_positions[end_idx]

  if start_idx > 1 then
    window_min_x = (column_positions[start_idx - 1] + column_positions[start_idx]) * 0.5
  end
  if end_idx < #column_positions then
    window_max_x = (column_positions[end_idx] + column_positions[end_idx + 1]) * 0.5
  end
  if window_max_x <= window_min_x then
    window_max_x = window_min_x + 1
  end

  return {
    min_x = window_min_x,
    min_y = map_bounds.min_y,
    max_x = window_max_x,
    max_y = map_bounds.max_y,
    width = window_max_x - window_min_x,
    height = map_bounds.height,
  }
end

---@param from_pos {x: number, y: number}
---@param to_pos {x: number, y: number}
---@param min_x number
---@param max_x number
---@return {x1: number, y1: number, x2: number, y2: number}|nil
function Minimap:_clip_edge_to_x_window(from_pos, to_pos, min_x, max_x)
  local x1, y1 = from_pos.x, from_pos.y
  local x2, y2 = to_pos.x, to_pos.y
  local dx = x2 - x1
  local dy = y2 - y1

  if math.abs(dx) < 0.0001 then
    if x1 < min_x or x1 > max_x then
      return nil
    end
    return {x1 = x1, y1 = y1, x2 = x2, y2 = y2}
  end

  local t_min = (min_x - x1) / dx
  local t_max = (max_x - x1) / dx
  if t_min > t_max then
    t_min, t_max = t_max, t_min
  end

  local t0 = math.max(0, t_min)
  local t1 = math.min(1, t_max)
  if t0 > t1 then
    return nil
  end

  return {
    x1 = x1 + dx * t0,
    y1 = y1 + dy * t0,
    x2 = x1 + dx * t1,
    y2 = y1 + dy * t1,
  }
end

function Minimap:draw()
  if not self.visible then
    return
  end

  love.graphics.setColor(0.1, 0.1, 0.15, 0.8)
  love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 4, 4)

  love.graphics.setColor(0.4, 0.4, 0.5, 0.8)
  love.graphics.rectangle("line", self.x, self.y, self.width, self.height, 4, 4)

  if not self.floor then
    love.graphics.setColor(0.6, 0.6, 0.6, 1)
    love.graphics.printf(i18n.t("ui.minimap"), self.x, self.y + self.height / 2 - 7, self.width, "center")
    return
  end

  local column_positions = self:_collect_column_positions()
  if #column_positions == 0 then
    return
  end
  local map_bounds = MapUtils.get_map_bounds(self.floor)
  if not map_bounds then
    return
  end

  local current_col_idx = self:_resolve_current_column_index(column_positions)
  local start_idx, end_idx = self:_resolve_visible_range(column_positions, current_col_idx)
  local visible_column_set = self:_build_visible_column_set(column_positions, start_idx, end_idx)
  local visible_nodes = self:_collect_visible_nodes(visible_column_set)
  local bounds = self:_build_window_bounds(map_bounds, column_positions, start_idx, end_idx)

  love.graphics.setColor(0.5, 0.5, 0.5, 0.4)
  love.graphics.setLineWidth(1)
  for _, edge in ipairs(self.floor:get_edges()) do
    local from_node = edge:get_from_node()
    local to_node = edge:get_to_node()
    local from_pos = from_node:get_position()
    local to_pos = to_node:get_position()

    local clipped = self:_clip_edge_to_x_window(from_pos, to_pos, bounds.min_x, bounds.max_x)
    if clipped then
      local fx, fy = self:_world_to_minimap(clipped.x1, clipped.y1, bounds)
      local tx, ty = self:_world_to_minimap(clipped.x2, clipped.y2, bounds)
      love.graphics.line(fx, fy, tx, ty)
    end
  end

  for _, node in ipairs(visible_nodes) do
    local pos = node:get_position()
    local mx, my = self:_world_to_minimap(pos.x, pos.y, bounds)
    local alpha = node:is_completed() and 0.4 or 0.9

    local color, _, is_boss = MapUtils.get_node_visual(node)
    local radius = is_boss and 4 or 3
    love.graphics.setColor(color[1], color[2], color[3], alpha)
    love.graphics.circle("fill", mx, my, radius)

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
