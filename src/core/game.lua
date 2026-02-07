local class = require('lib.middleclass')
local SceneManager = require('src.core.scene_manager')
local EventBus = require('src.core.event_bus')

local Game = class('Game')

-- Singleton instance
local instance = nil

function Game.static:getInstance()
    if not instance then
        instance = Game:new()
    end
    return instance
end

function Game:initialize()
    self.scene_manager = nil
    self.event_bus = nil
end

function Game:init()
    self.scene_manager = SceneManager:new()
    self.event_bus = EventBus:new()

    -- 초기 Scene 설정: MapScene으로 시작
    -- MapScene은 require가 Game:init() 내부에서 호출되어 순환 참조 방지
    local MapScene = require('src.scene.map_scene')
    self.scene_manager:push(MapScene:new())
end

function Game:update(dt)
    if self.scene_manager then
        self.scene_manager:update(dt)
    end
end

function Game:draw()
    if self.scene_manager then
        self.scene_manager:draw()
    end
end

function Game:keypressed(key)
    if self.scene_manager then
        self.scene_manager:keypressed(key)
    end
end

function Game:mousepressed(x, y, button)
    if self.scene_manager then
        self.scene_manager:mousepressed(x, y, button)
    end
end

return Game
