local class = require('lib.middleclass')
local Gauge = require('src.ui.gauge')
local Button = require('src.ui.button')

---@class CombatHandler
---@field hero_gauge Gauge
---@field enemy_gauge Gauge
---@field end_button Button
---@field on_end_callback function|nil
---@field enemy_world_x number     -- enemy position in world coords (for slide-in animation)
---@field enemy_world_y number
---@field ui_offset_y number       -- combat UI vertical offset (for slide-up animation)
---@field active boolean
local CombatHandler = class('CombatHandler')

---Constructor
---@param params table { on_end_callback = function }
function CombatHandler:initialize(params)
  params = params or {}

  -- Create hero gauge at (50, 100, 200, 30) with green color, label "Hero HP", value 100/100
  self.hero_gauge = Gauge:new(50, 100, 200, 30)
  self.hero_gauge.label = "Hero HP"
  self.hero_gauge.fg_color = { 0, 1, 0 }
  self.hero_gauge:set_value(100, 100)

  -- Create enemy gauge at (800, 100, 200, 30) with red color, label "Enemy HP", value 50/100
  self.enemy_gauge = Gauge:new(800, 100, 200, 30)
  self.enemy_gauge.label = "Enemy HP"
  self.enemy_gauge.fg_color = { 1, 0, 0 }
  self.enemy_gauge:set_value(50, 100)

  -- Create end button at (640-50, 650, 100, 40) with text "전투 종료"
  self.end_button = Button:new(640 - 50, 650, 100, 40, "전투 종료")
  self.end_button:set_on_click(function()
    if self.on_end_callback then
      self.on_end_callback()
    end
  end)

  self.on_end_callback = params.on_end_callback

  -- Animation fields
  self.enemy_world_x = 1280 + 200  -- off-screen right, for slide-in
  self.enemy_world_y = 300
  self.ui_offset_y = 200  -- below screen, for slide-up

  self.active = false
end

---Activate combat handler
function CombatHandler:activate()
  self.active = true
end

---Deactivate combat handler
function CombatHandler:deactivate()
  self.active = false
end

---Update combat handler
---@param dt number Delta time
function CombatHandler:update(dt)
  if not self.active then return end

  self.hero_gauge:update(dt)
  self.enemy_gauge:update(dt)
  self.end_button:update(dt)
end

---Draw world elements (enemy)
---@param camera_x number Camera X position (not used, we draw in world coords)
function CombatHandler:draw_world(camera_x)
  -- Draw enemy placeholder (red circle radius 40) at enemy_world_x, enemy_world_y
  love.graphics.setColor(1, 0, 0)
  love.graphics.circle('fill', self.enemy_world_x, self.enemy_world_y, 40)
  love.graphics.setColor(1, 1, 1)
end

---Draw UI elements (gauges, button, overlay text)
function CombatHandler:draw_ui()
  -- Draw background overlay text "전투 중" at top center
  love.graphics.setColor(1, 1, 1, 0.8)
  love.graphics.printf("전투 중", 0, 30, 1280, 'center')

  -- Translate gauges and button by ui_offset_y for slide-up animation
  love.graphics.push()
  love.graphics.translate(0, self.ui_offset_y)

  self.hero_gauge:draw()
  self.enemy_gauge:draw()
  self.end_button:draw()

  love.graphics.pop()
  love.graphics.setColor(1, 1, 1)
end

---Handle mouse press
---@param x number Mouse X position
---@param y number Mouse Y position
---@param button number Mouse button
function CombatHandler:mousepressed(x, y, button)
  if not self.active then return end

  -- Adjust mouse coords by ui_offset_y for button/gauge hit testing
  local adjusted_y = y - self.ui_offset_y

  self.hero_gauge:mousepressed(x, adjusted_y, button)
  self.enemy_gauge:mousepressed(x, adjusted_y, button)
  self.end_button:mousepressed(x, adjusted_y, button)
end

---Set on_end callback
---@param callback function Callback function
function CombatHandler:set_on_end(callback)
  self.on_end_callback = callback
end

return CombatHandler
