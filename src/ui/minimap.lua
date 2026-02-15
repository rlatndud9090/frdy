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
  self.padding = 10
  self.visible_column_count = 5
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
---@return table<number, boolean>
function Minimap:_build_visible_column_set(column_positions, start_idx)
  local visible_set = {}
  local end_idx = math.min(start_idx + self.visible_column_count - 1, #column_positions)
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

---@param nodes Node[]
---@return table|nil
function Minimap:_get_bounds_for_nodes(nodes)
  if #nodes == 0 then
    return nil
  end

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
  if w < 1 then w = 1 end
  if h < 1 then h = 100 end

  return {min_x = min_x, min_y = min_y, max_x = max_x, max_y = max_y, width = w, height = h}
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

  local current_col_idx = self:_resolve_current_column_index(column_positions)
  local visible_column_set = self:_build_visible_column_set(column_positions, current_col_idx)
  local visible_nodes = self:_collect_visible_nodes(visible_column_set)
  local bounds = self:_get_bounds_for_nodes(visible_nodes)
  if not bounds then
    return
  end

  love.graphics.setColor(0.5, 0.5, 0.5, 0.4)
  love.graphics.setLineWidth(1)
  for _, edge in ipairs(self.floor:get_edges()) do
    local from_node = edge:get_from_node()
    local to_node = edge:get_to_node()
    local from_pos = from_node:get_position()
    local to_pos = to_node:get_position()

    if visible_column_set[from_pos.x] and visible_column_set[to_pos.x] then
      local fx, fy = MapUtils.world_to_view(from_pos.x, from_pos.y, bounds, self.x, self.y, self.width, self.height, self.padding)
      local tx, ty = MapUtils.world_to_view(to_pos.x, to_pos.y, bounds, self.x, self.y, self.width, self.height, self.padding)
      love.graphics.line(fx, fy, tx, ty)
    end
  end

  for _, node in ipairs(visible_nodes) do
    local pos = node:get_position()
    local mx, my = MapUtils.world_to_view(pos.x, pos.y, bounds, self.x, self.y, self.width, self.height, self.padding)
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