local class = require("lib.middleclass")
local flux = require("lib.flux")
local Button = require("src.ui.button")
local MapUtils = require("src.ui.map_utils")
local i18n = require("src.i18n.init")

--- 전체 맵 시각화 오버레이. GameScene 내부 UI 모듈.
--- UIElement를 상속하지 않음: 전체화면 오버레이로 x/y/width/height 위치 개념이 불필요.
--- SceneManager push 시 GameScene tween이 멈추는 문제를 회피하기 위해 별도 Scene이 아닌 내부 모듈로 구현.
---@class MapOverlay
---@field floor Floor|nil
---@field current_node Node|nil
---@field visible boolean
---@field is_closing boolean
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
  self.visible = false
  self.is_closing = false
  self.alpha = 0
  self.padding = 60
  self.on_close_callback = nil

  self.close_button = Button:new(SCREEN_W - 80, 20, 60, 30, "ui.close")
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
  if self.visible then return end
  self.floor = floor
  self.current_node = current_node
  self.visible = true
  self.alpha = 0
  self.close_button:set_visible(true)

  flux.to(self, 0.3, {alpha = 1}):ease("quadout")
end

function MapOverlay:close()
  if not self.visible or self.is_closing then return end
  self.is_closing = true

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

---@param dt number
function MapOverlay:update(dt)
  if not self.visible then return end
  self.close_button:update(dt)
end

function MapOverlay:draw()
  if not self.visible then return end

  -- 어둠 배경
  love.graphics.setColor(0, 0, 0, 0.85 * self.alpha)
  love.graphics.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)

  if not self.floor then return end
  local bounds = MapUtils.get_map_bounds(self.floor)
  if not bounds then return end

  -- 타이틀
  love.graphics.setColor(1, 1, 1, self.alpha)
  love.graphics.printf(i18n.t("ui.full_map"), 0, 20, SCREEN_W, "center")

  -- 엣지 그리기
  love.graphics.setColor(0.5, 0.5, 0.5, 0.5 * self.alpha)
  love.graphics.setLineWidth(2)
  for _, edge in ipairs(self.floor:get_edges()) do
    local from_pos = edge:get_from_node():get_position()
    local to_pos = edge:get_to_node():get_position()
    local fx, fy = MapUtils.world_to_view(from_pos.x, from_pos.y, bounds, 0, 0, SCREEN_W, SCREEN_H, self.padding)
    local tx, ty = MapUtils.world_to_view(to_pos.x, to_pos.y, bounds, 0, 0, SCREEN_W, SCREEN_H, self.padding)
    love.graphics.line(fx, fy, tx, ty)
  end

  -- 노드 그리기
  for _, node in ipairs(self.floor:get_nodes()) do
    local pos = node:get_position()
    local sx, sy = MapUtils.world_to_view(pos.x, pos.y, bounds, 0, 0, SCREEN_W, SCREEN_H, self.padding)
    local completed = node:is_completed()
    local alpha = (completed and 0.5 or 1.0) * self.alpha

    local color, label, is_boss = MapUtils.get_node_visual(node)
    local radius = is_boss and 22 or 16
    love.graphics.setColor(color[1], color[2], color[3], alpha)

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
    local font = love.graphics.getFont()
    local tw = font:getWidth(label)
    love.graphics.print(label, sx - tw / 2, sy + radius + 4)
  end

  love.graphics.setLineWidth(1)

  -- 닫기 버튼
  self.close_button:draw()

  -- 안내 텍스트
  love.graphics.setColor(0.6, 0.6, 0.6, self.alpha)
  love.graphics.printf(i18n.t("ui.close_hint"), 0, SCREEN_H - 30, SCREEN_W, "center")
end

---@param key string
function MapOverlay:keypressed(key)
  if not self.visible then return end
  if key == "escape" or key == "m" then
    self:close()
  end
end

---@param mx number
---@param my number
---@param button number
function MapOverlay:mousepressed(mx, my, button)
  if not self.visible then return end
  self.close_button:mousepressed(mx, my, button)
end

return MapOverlay
