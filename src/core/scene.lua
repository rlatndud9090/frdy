local class = require('lib.middleclass')

---@class Scene
---@field class table
---@field new fun(self: Scene): Scene
local Scene = class('Scene')

function Scene:initialize()
  --- Base initialization (subclasses can extend)
end

--- Called when scene becomes active
---@param params? table
function Scene:enter(params)
  --- No-op by default
end

--- Called when scene is removed
function Scene:exit()
  --- No-op by default
end

--- Called every frame
---@param dt number
function Scene:update(dt)
  --- No-op by default
end

--- Called every frame for rendering
function Scene:draw()
  --- No-op by default
end

--- Called on key press
---@param key string
function Scene:keypressed(key)
  --- No-op by default
end

--- Called on mouse click
---@param x number
---@param y number
---@param button number
function Scene:mousepressed(x, y, button)
  --- No-op by default
end

return Scene
