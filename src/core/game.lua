local class = require('lib.middleclass')
local SceneManager = require('src.core.scene_manager')
local EventBus = require('src.core.event_bus')

---@class Game
---@field scene_manager SceneManager|nil
---@field event_bus EventBus|nil
---@field new fun(self: Game): Game
---@field static table
local Game = class('Game')

--- Singleton instance
---@type Game|nil
local instance = nil

---@return Game
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

    --- 초기 Scene 설정: GameScene으로 시작 (통합 게임플레이 씬)
    local GameScene = require('src.scene.game_scene')
    self.scene_manager:push(GameScene:new())
end

---@param dt number
function Game:update(dt)
    local flux = require('lib.flux')
    flux.update(dt)

    if self.scene_manager then
        self.scene_manager:update(dt)
    end
end

function Game:draw()
    if self.scene_manager then
        self.scene_manager:draw()
    end
end

---@param key string
function Game:keypressed(key)
    if self.scene_manager then
        self.scene_manager:keypressed(key)
    end
end

---@param x number
---@param y number
---@param button number
function Game:mousepressed(x, y, button)
    if self.scene_manager then
        self.scene_manager:mousepressed(x, y, button)
    end
end

return Game
