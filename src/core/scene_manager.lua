local class = require('lib.middleclass')

local SceneManager = class('SceneManager')

function SceneManager:initialize()
    self.stack = {}
end

-- Add a scene to the stack and call its enter method
function SceneManager:push(scene, params)
    if scene then
        table.insert(self.stack, scene)
        if scene.enter then
            scene:enter(params)
        end
    end
end

-- Remove the top scene from the stack and call its exit method
function SceneManager:pop()
    if #self.stack > 0 then
        local scene = table.remove(self.stack)
        if scene and scene.exit then
            scene:exit()
        end
        return scene
    end
    return nil
end

-- Replace the current scene (pop then push)
function SceneManager:switch(scene, params)
    self:pop()
    self:push(scene, params)
end

-- Return the top scene without removing it
function SceneManager:peek()
    if #self.stack > 0 then
        return self.stack[#self.stack]
    end
    return nil
end

-- Update the top scene
function SceneManager:update(dt)
    local current = self:peek()
    if current and current.update then
        current:update(dt)
    end
end

-- Draw all scenes in the stack (bottom to top) for overlay support
function SceneManager:draw()
    for i = 1, #self.stack do
        local scene = self.stack[i]
        if scene and scene.draw then
            scene:draw()
        end
    end
end

-- Delegate keypressed to the top scene
function SceneManager:keypressed(key)
    local current = self:peek()
    if current and current.keypressed then
        current:keypressed(key)
    end
end

-- Delegate mousepressed to the top scene
function SceneManager:mousepressed(x, y, button)
    local current = self:peek()
    if current and current.mousepressed then
        current:mousepressed(x, y, button)
    end
end

return SceneManager
