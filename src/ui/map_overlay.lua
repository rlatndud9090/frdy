local class = require("lib.middleclass")
local flux = require("lib.flux")
local Button = require("src.ui.button")

---@class MapOverlay
---@field floor Floor|nil
---@field current_node Node|nil
---@field is_visible boolean
---@field alpha number
---@field close_button Button
---@field padding number
---@field on_close_callback function|nil
local MapOverlay = class("MapOverlay")

local SCREEN_W = 1280
local SCREEN_H = 720

function MapOverlay:initialize()
  self.floor = nil
  self.current_node = nil
  self.is_visible = false
  self.alpha = 0
  self.padding = 60
  self.on_close_callback = nil

  self.close_button = Button:new(SCREEN_W - 80, 20, 60, 30, "닫기")
  self.close_button:set_visible(false)
  self.close_button:set_on_click(function()
    self:close()
  end)
end

---@param callback function
function MapOverlay:set_on_close(callback)
  self.on_close_callback = callback
end

---@param floor Floor
---@param current_node Node|nil
function MapOverlay:open(floor, current_node)
  if self.is_visible then return end
  self.floor = floor
  self.current_node = current_node
  self.is_visible = true
  self.alpha = 0
  self.close_button:set_visible(true)

  flux.to(self, 0.3, {alpha = 1}):ease("quadout")
end

function MapOverlay:close()
  if not self.is_visible then return end

  flux.to(self, 0.2, {alpha = 0})
    :ease("quadin")
    :oncomplete(function()
      self.is_visible = false
      self.close_button:set_visible(false)
      if self.on_close_callback then
        self.on_close_callback()
      end
    end)
end

---@return boolean
function MapOverlay:is_open()
  return self.is_visible
end

---@param dt number
function MapOverlay:update(dt)
  if not self.is_visible then return end
  self.close_button:update(dt)
end

--- 맵 노드들의 월드 좌표 바운드 계산
---@return table|nil
function MapOverlay:_get_map_bounds()
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
  if w < 1 then w = 1 end
  if h < 1 then h = 100 end

  return {min_x = min_x, min_y = min_y, max_x = max_x, max_y = max_y, width = w, height = h}
end

--- 월드 좌표 → 오버레이 화면 좌표 변환
---@param world_x number
---@param world_y number
---@param bounds table
---@return number, number
function MapOverlay:_world_to_screen(world_x, world_y, bounds)
  local area_w = SCREEN_W - self.padding * 2
  local area_h = SCREEN_H - self.padding * 2

  local scale_x = area_w / bounds.width
  local scale_y = area_h / bounds.height
  local scale = math.min(scale_x, scale_y)

  local used_w = bounds.width * scale
  local used_h = bounds.height * scale
  local offset_x = (area_w - used_w) / 2
  local offset_y = (area_h - used_h) / 2

  local sx = self.padding + offset_x + (world_x - bounds.min_x) * scale
  local sy = self.padding + offset_y + (world_y - bounds.min_y) * scale
  return sx, sy
end

function MapOverlay:draw()
  if not self.is_visible then return end

  -- 어둠 배경
  love.graphics.setColor(0, 0, 0, 0.85 * self.alpha)
  love.graphics.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)

  if not self.floor then return end
  local bounds = self:_get_map_bounds()
  if not bounds then return end

  -- 타이틀
  love.graphics.setColor(1, 1, 1, self.alpha)
  love.graphics.printf("전체 맵", 0, 20, SCREEN_W, "center")

  -- 엣지 그리기
  love.graphics.setColor(0.5, 0.5, 0.5, 0.5 * self.alpha)
  love.graphics.setLineWidth(2)
  for _, edge in ipairs(self.floor.edges) do
    local from_pos = edge:get_from_node():get_position()
    local to_pos = edge:get_to_node():get_position()
    local fx, fy = self:_world_to_screen(from_pos.x, from_pos.y, bounds)
    local tx, ty = self:_world_to_screen(to_pos.x, to_pos.y, bounds)
    love.graphics.line(fx, fy, tx, ty)
  end

  -- 노드 그리기
  for _, node in ipairs(self.floor:get_nodes()) do
    local pos = node:get_position()
    local sx, sy = self:_world_to_screen(pos.x, pos.y, bounds)
    local node_type = node:get_type()
    local completed = node:is_completed()
    local alpha = (completed and 0.5 or 1.0) * self.alpha

    local radius = 16
    if node_type == "combat" then
      if node.is_boss and node:is_boss() then
        love.graphics.setColor(0.8, 0.1, 0.1, alpha)
        radius = 22
      else
        love.graphics.setColor(0.3, 0.3, 0.8, alpha)
      end
    elseif node_type == "event" then
      love.graphics.setColor(0.2, 0.7, 0.3, alpha)
    end

    love.graphics.circle("fill", sx, sy, radius)

    -- 완료 노드 체크마크 표시
    if completed then
      love.graphics.setColor(1, 1, 1, 0.6 * self.alpha)
      love.graphics.setLineWidth(2)
      love.graphics.line(sx - 5, sy, sx - 1, sy + 4, sx + 6, sy - 5)
    end

    -- 현재 노드 강조
    if node == self.current_node then
      love.graphics.setColor(1, 0.8, 0, self.alpha)
      love.graphics.setLineWidth(3)
      love.graphics.circle("line", sx, sy, radius + 4)
    end

    -- 노드 타입 라벨
    love.graphics.setColor(1, 1, 1, alpha)
    local label = ""
    if node_type == "combat" then
      if node.is_boss and node:is_boss() then
        label = "BOSS"
      else
        label = "전투"
      end
    elseif node_type == "event" then
      label = "이벤트"
    end
    local font = love.graphics.getFont()
    local tw = font:getWidth(label)
    love.graphics.print(label, sx - tw / 2, sy + radius + 4)
  end

  love.graphics.setLineWidth(1)

  -- 닫기 버튼
  self.close_button:draw()

  -- 안내 텍스트
  love.graphics.setColor(0.6, 0.6, 0.6, self.alpha)
  love.graphics.printf("ESC 또는 M 키로 닫기", 0, SCREEN_H - 30, SCREEN_W, "center")
end

---@param key string
function MapOverlay:keypressed(key)
  if not self.is_visible then return false end
  if key == "escape" or key == "m" then
    self:close()
    return true
  end
  return false
end

---@param mx number
---@param my number
---@param button number
function MapOverlay:mousepressed(mx, my, button)
  if not self.is_visible then return false end
  self.close_button:mousepressed(mx, my, button)
  return true  -- 이벤트 소비 (아래 UI에 전달하지 않음)
end

return MapOverlay
