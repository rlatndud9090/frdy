local class = require("lib.middleclass")
local flux = require("lib.flux")
local Button = require("src.ui.button")
local MapUtils = require("src.ui.map_utils")
local i18n = require("src.i18n.init")

---@class MapOverlay
---@field floor Floor|nil
---@field current_node Node|nil
---@field visible boolean
---@field is_closing boolean
---@field alpha number
---@field close_button Button
---@field padding number
---@field on_close_callback function|nil
---@field map_view_x number
---@field map_view_y number
---@field map_view_w number
---@field map_view_h number
---@field bounds table|nil
---@field zoom number
---@field pan_x number
---@field pan_y number
---@field drag_active boolean
---@field drag_last_x number
---@field drag_last_y number
local MapOverlay = class("MapOverlay")

local SCREEN_W = 1280
local SCREEN_H = 720
local DEFAULT_ZOOM = 2.0

---@param value number
---@param min_value number
---@param max_value number
---@return number
local function clamp(value, min_value, max_value)
  if value < min_value then
    return min_value
  end
  if value > max_value then
    return max_value
  end
  return value
end

---@return nil
function MapOverlay:initialize()
  self.floor = nil
  self.current_node = nil
  self.visible = false
  self.is_closing = false
  self.alpha = 0
  self.padding = 24
  self.on_close_callback = nil

  self.map_view_x = 40
  self.map_view_y = 80
  self.map_view_w = SCREEN_W - 80
  self.map_view_h = SCREEN_H - 170

  self.bounds = nil
  self.zoom = DEFAULT_ZOOM
  self.pan_x = 0
  self.pan_y = 0
  self.drag_active = false
  self.drag_last_x = 0
  self.drag_last_y = 0

  self.close_button = Button:new(SCREEN_W - 80, 20, 60, 30, "ui.close")
  self.close_button:set_visible(false)
  self.close_button:set_on_click(function()
    self:close()
  end)
end

---@param callback function
---@return nil
function MapOverlay:set_on_close(callback)
  self.on_close_callback = callback
end

---@param floor Floor
---@param current_node Node|nil
---@return nil
function MapOverlay:open(floor, current_node)
  if self.visible then
    return
  end

  self.floor = floor
  self.current_node = current_node
  self.visible = true
  self.alpha = 0
  self.drag_active = false
  self.close_button:set_visible(true)

  self.bounds = floor and MapUtils.get_map_bounds(floor) or nil
  if self.bounds then
    self.zoom = DEFAULT_ZOOM
    if self.current_node then
      local pos = self.current_node:get_position()
      self.pan_x = pos.x
    else
      self.pan_x = (self.bounds.min_x + self.bounds.max_x) * 0.5
    end
    self.pan_y = (self.bounds.min_y + self.bounds.max_y) * 0.5
    self:_clamp_pan()
  end

  flux.to(self, 0.3, {alpha = 1}):ease("quadout")
end

---@return nil
function MapOverlay:close()
  if not self.visible or self.is_closing then
    return
  end

  self.is_closing = true
  self.drag_active = false
  flux.to(self, 0.2, {alpha = 0})
    :ease("quadin")
    :oncomplete(function()
      self.visible = false
      self.is_closing = false
      self.close_button:set_visible(false)
      if self.on_close_callback then
        self.on_close_callback()
      end
    end)
end

---@return boolean
function MapOverlay:is_open()
  return self.visible
end

---@param bounds table
---@return number
function MapOverlay:_get_base_scale(bounds)
  local inner_h = math.max(1, self.map_view_h - self.padding * 2)
  local scale_y = inner_h / math.max(bounds.height, 1)
  return math.max(0.0001, scale_y)
end

---@return number, number
function MapOverlay:_get_draw_scales()
  if not self.bounds then
    return 0.0001, 0.0001
  end
  local base_scale = self:_get_base_scale(self.bounds)
  local scale_y = base_scale
  local scale_x = base_scale * self.zoom
  return math.max(0.0001, scale_x), math.max(0.0001, scale_y)
end

---@return nil
function MapOverlay:_clamp_pan()
  if not self.bounds then
    return
  end

  local scale_x, _ = self:_get_draw_scales()
  local inner_w = math.max(1, self.map_view_w - self.padding * 2)
  local half_world_w = (inner_w * 0.5) / scale_x

  local center_x = (self.bounds.min_x + self.bounds.max_x) * 0.5
  local center_y = (self.bounds.min_y + self.bounds.max_y) * 0.5
  local min_pan_x = self.bounds.min_x + half_world_w
  local max_pan_x = self.bounds.max_x - half_world_w

  if min_pan_x > max_pan_x then
    self.pan_x = center_x
  else
    self.pan_x = clamp(self.pan_x, min_pan_x, max_pan_x)
  end

  -- Keep vertical focus fixed; only horizontal scrolling is allowed.
  self.pan_y = center_y
end

---@param world_x number
---@param world_y number
---@return number, number
function MapOverlay:_world_to_view(world_x, world_y)
  local scale_x, scale_y = self:_get_draw_scales()
  local center_x = self.map_view_x + self.map_view_w * 0.5
  local center_y = self.map_view_y + self.map_view_h * 0.5
  local sx = center_x + (world_x - self.pan_x) * scale_x
  local sy = center_y + (world_y - self.pan_y) * scale_y
  return sx, sy
end

---@param mx number
---@param my number
---@return boolean
function MapOverlay:_in_map_view(mx, my)
  return mx >= self.map_view_x
    and mx <= self.map_view_x + self.map_view_w
    and my >= self.map_view_y
    and my <= self.map_view_y + self.map_view_h
end

---@param dt number
---@return nil
function MapOverlay:update(dt)
  if not self.visible then
    return
  end

  self.close_button:update(dt)

  if self.drag_active then
    if not love.mouse.isDown(1) then
      self.drag_active = false
      return
    end

    local mx, my = love.mouse.getPosition()
    local scale_x, _ = self:_get_draw_scales()
    local dx = mx - self.drag_last_x
    self.drag_last_x = mx
    self.drag_last_y = my

    self.pan_x = self.pan_x - dx / scale_x
    self:_clamp_pan()
  end
end

---@return nil
function MapOverlay:draw()
  if not self.visible then
    return
  end

  love.graphics.setColor(0, 0, 0, 0.85 * self.alpha)
  love.graphics.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)

  if not self.floor then
    return
  end

  if not self.bounds then
    self.bounds = MapUtils.get_map_bounds(self.floor)
  end
  if not self.bounds then
    return
  end

  love.graphics.setColor(1, 1, 1, self.alpha)
  love.graphics.printf(i18n.t("ui.full_map"), 0, 20, SCREEN_W, "center")

  -- Map viewport panel.
  love.graphics.setColor(0.12, 0.12, 0.15, 0.92 * self.alpha)
  love.graphics.rectangle("fill", self.map_view_x, self.map_view_y, self.map_view_w, self.map_view_h, 6, 6)
  love.graphics.setColor(0.6, 0.6, 0.7, 0.9 * self.alpha)
  love.graphics.rectangle("line", self.map_view_x, self.map_view_y, self.map_view_w, self.map_view_h, 6, 6)

  love.graphics.setScissor(self.map_view_x, self.map_view_y, self.map_view_w, self.map_view_h)

  love.graphics.setColor(0.5, 0.5, 0.5, 0.6 * self.alpha)
  love.graphics.setLineWidth(2)
  for _, edge in ipairs(self.floor:get_edges()) do
    local from_pos = edge:get_from_node():get_position()
    local to_pos = edge:get_to_node():get_position()
    local fx, fy = self:_world_to_view(from_pos.x, from_pos.y)
    local tx, ty = self:_world_to_view(to_pos.x, to_pos.y)
    love.graphics.line(fx, fy, tx, ty)
  end

  for _, node in ipairs(self.floor:get_nodes()) do
    local pos = node:get_position()
    local sx, sy = self:_world_to_view(pos.x, pos.y)
    local completed = node:is_completed()
    local alpha = (completed and 0.5 or 1.0) * self.alpha

    local color, label, is_boss = MapUtils.get_node_visual(node)
    local radius = is_boss and 22 or 16
    love.graphics.setColor(color[1], color[2], color[3], alpha)
    love.graphics.circle("fill", sx, sy, radius)

    if completed then
      love.graphics.setColor(1, 1, 1, 0.6 * self.alpha)
      love.graphics.setLineWidth(2)
      love.graphics.line(sx - 5, sy, sx - 1, sy + 4, sx + 6, sy - 5)
    end

    if node == self.current_node then
      love.graphics.setColor(1, 0.8, 0, self.alpha)
      love.graphics.setLineWidth(3)
      love.graphics.circle("line", sx, sy, radius + 4)
    end

    love.graphics.setColor(1, 1, 1, alpha)
    local font = love.graphics.getFont()
    local tw = font:getWidth(label)
    love.graphics.print(label, sx - tw * 0.5, sy + radius + 4)
  end

  love.graphics.setScissor()
  love.graphics.setLineWidth(1)

  self.close_button:draw()

  love.graphics.setColor(0.75, 0.75, 0.75, self.alpha)
  love.graphics.printf("Drag/Wheel: horizontal only (vertical fully shown)", 0, SCREEN_H - 50, SCREEN_W, "center")
  love.graphics.printf(i18n.t("ui.close_hint"), 0, SCREEN_H - 30, SCREEN_W, "center")
end

---@param key string
---@return nil
function MapOverlay:keypressed(key)
  if not self.visible then
    return
  end

  if key == "escape" or key == "m" then
    self:close()
  end
end

---@param mx number
---@param my number
---@param button number
---@return nil
function MapOverlay:mousepressed(mx, my, button)
  if not self.visible then
    return
  end

  self.close_button:mousepressed(mx, my, button)

  if button == 1 and self:_in_map_view(mx, my) then
    self.drag_active = true
    self.drag_last_x = mx
    self.drag_last_y = my
  end
end

---@param x number
---@param y number
---@return nil
function MapOverlay:wheelmoved(x, y)
  if not self.visible or not self.bounds then
    return
  end

  local scale_x, _ = self:_get_draw_scales()
  local world_step_x = (self.map_view_w / scale_x) * 0.14

  -- Vertical wheel and horizontal wheel both move horizontally across the map.
  self.pan_x = self.pan_x - (y + x) * world_step_x
  self:_clamp_pan()
end

return MapOverlay
