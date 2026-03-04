local class = require('lib.middleclass')
local flux = require('lib.flux')
local RNG = require('src.core.rng')

---@class Camera
---@field x number current camera center world X
---@field y number current camera center world Y
---@field target_x number smooth follow target X
---@field target_y number smooth follow target Y
---@field smoothing number lerp speed (higher = faster follow)
---@field shake_amount number current shake intensity
---@field shake_timer number remaining shake duration
---@field _active_tween table|nil reference to active move tween for cancellation
---@field _shake_offset_x number
---@field _shake_offset_y number
---@field rng RNG
local Camera = class('Camera')

---Initialize camera with default values
---@param rng? RNG
---@return nil
function Camera:initialize(rng)
  self.x = 0
  self.y = 0
  self.target_x = 0
  self.target_y = 0
  self.smoothing = 5
  self.shake_amount = 0
  self.shake_timer = 0
  self._active_tween = nil
  self._shake_offset_x = 0
  self._shake_offset_y = 0
  self.rng = rng or RNG:new(os.time())
end

---@param rng RNG
---@return nil
function Camera:set_rng(rng)
  self.rng = rng
end

---Update camera position with smooth following and shake
---@param dt number delta time
---@return nil
function Camera:update(dt)
  -- Smooth follow target
  self.x = self.x + (self.target_x - self.x) * self.smoothing * dt
  self.y = self.y + (self.target_y - self.y) * self.smoothing * dt

  -- Update shake timer
  if self.shake_timer > 0 then
    self.shake_timer = self.shake_timer - dt
    if self.shake_timer <= 0 then
      self.shake_timer = 0
      self.shake_amount = 0
      self._shake_offset_x = 0
      self._shake_offset_y = 0
    else
      self._shake_offset_x = (self.rng:next_float() * 2 - 1) * self.shake_amount
      self._shake_offset_y = (self.rng:next_float() * 2 - 1) * self.shake_amount
    end
  else
    self._shake_offset_x = 0
    self._shake_offset_y = 0
  end
end

---Set target position for smooth following
---@param tx number target world X
---@param ty number target world Y
---@return nil
function Camera:set_target(tx, ty)
  self.target_x = tx
  self.target_y = ty
end

---Move camera to position with tween animation
---@param tx number target world X
---@param ty number target world Y
---@param duration number tween duration in seconds
---@param ease? string easing function name (default: "quadout")
---@return nil
function Camera:move_to(tx, ty, duration, ease)
  ease = ease or "quadout"

  -- Cancel existing tween
  if self._active_tween then
    self._active_tween:stop()
    self._active_tween = nil
  end

  -- Create new tween
  self._active_tween = flux.to(self, duration, {
    target_x = tx,
    target_y = ty
  }):ease(ease):oncomplete(function()
    self._active_tween = nil
  end)
end

---Add screen shake effect
---@param intensity number shake intensity
---@param duration number shake duration in seconds
---@return nil
function Camera:shake(intensity, duration)
  self.shake_amount = intensity
  self.shake_timer = duration

  -- Decay shake amount to 0 over duration
  flux.to(self, duration, { shake_amount = 0 })
end

---Apply camera transformation (call before drawing world)
---@return nil
function Camera:apply()
  local screen_width = love.graphics.getWidth()
  local screen_height = love.graphics.getHeight()

  -- Calculate base offset to center camera
  local offset_x = -(self.x - screen_width / 2)
  local offset_y = -(self.y - screen_height / 2)

  -- Add shake offset
  offset_x = offset_x + self._shake_offset_x
  offset_y = offset_y + self._shake_offset_y

  love.graphics.push()
  love.graphics.translate(offset_x, offset_y)
end

---Release camera transformation (call after drawing world)
---@return nil
function Camera:release()
  love.graphics.pop()
end

---Get current camera offset
---@return number offset_x
---@return number offset_y
function Camera:get_offset()
  local screen_width = love.graphics.getWidth()
  local screen_height = love.graphics.getHeight()

  local offset_x = -(self.x - screen_width / 2)
  local offset_y = -(self.y - screen_height / 2)

  -- Add shake offset if active
  offset_x = offset_x + self._shake_offset_x
  offset_y = offset_y + self._shake_offset_y

  return offset_x, offset_y
end

---Convert screen coordinates to world coordinates
---@param sx number screen X
---@param sy number screen Y
---@return number world_x
---@return number world_y
function Camera:screen_to_world(sx, sy)
  local offset_x, offset_y = self:get_offset()
  return sx - offset_x, sy - offset_y
end

return Camera
