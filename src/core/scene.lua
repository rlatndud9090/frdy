local class = require('lib.middleclass')

local Scene = class('Scene')

function Scene:initialize()
  -- Base initialization (subclasses can extend)
end

-- Called when scene becomes active
function Scene:enter(params)
  -- No-op by default
end

-- Called when scene is removed
function Scene:exit()
  -- No-op by default
end

-- Called every frame
function Scene:update(dt)
  -- No-op by default
end

-- Called every frame for rendering
function Scene:draw()
  -- No-op by default
end

-- Called on key press
function Scene:keypressed(key)
  -- No-op by default
end

-- Called on mouse click
function Scene:mousepressed(x, y, button)
  -- No-op by default
end

return Scene
