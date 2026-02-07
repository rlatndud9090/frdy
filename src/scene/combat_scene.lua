local class = require('lib.middleclass')
local Scene = require("src.core.scene")
local Gauge = require("src.ui.gauge")
local Button = require("src.ui.button")
local Game = require('src.core.game')

local CombatScene = class('CombatScene', Scene)

function CombatScene:initialize()
    Scene.initialize(self)

    -- 용사 HP 게이지 생성 (50, 100, 200, 30, "Hero HP")
    self.hero_gauge = Gauge:new(50, 100, 200, 30)
    self.hero_gauge.label = "Hero HP"
    self.hero_gauge.fg_color = {0, 1, 0}  -- 초록색
    self.hero_gauge:set_value(100, 100)

    -- 적 HP 게이지 생성 (800, 100, 200, 30, "Enemy HP")
    self.enemy_gauge = Gauge:new(800, 100, 200, 30)
    self.enemy_gauge.label = "Enemy HP"
    self.enemy_gauge.fg_color = {1, 0, 0}  -- 빨강색
    self.enemy_gauge:set_value(50, 100)

    -- "전투 종료" 버튼 생성 (클릭 시 MapScene으로 복귀)
    self.end_button = Button:new(640 - 50, 650, 100, 40, "전투 종료")
    self.end_button:set_on_click(function()
        Game:getInstance().scene_manager:pop()
    end)
end

function CombatScene:enter()
    -- 진입 시 초기화
    self:initialize()
end

function CombatScene:update(dt)
    -- UI 위젯 업데이트
    self.hero_gauge:update(dt)
    self.enemy_gauge:update(dt)
    self.end_button:update(dt)
end

function CombatScene:draw()
    -- 배경색 설정
    love.graphics.setColor(0.1, 0.1, 0.2, 1)
    love.graphics.rectangle("fill", 0, 0, 1280, 720)

    -- "전투 화면 (Placeholder)" 텍스트
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf("전투 화면 (Placeholder)", 0, 50, 1280, "center")

    -- 게이지들 그리기
    self.hero_gauge:draw()
    self.enemy_gauge:draw()

    -- 버튼 그리기
    self.end_button:draw()
end

function CombatScene:mousepressed(x, y, button)
    -- UI 위젯에 전달
    self.hero_gauge:mousepressed(x, y, button)
    self.enemy_gauge:mousepressed(x, y, button)
    self.end_button:mousepressed(x, y, button)
end

function CombatScene:keypressed(key)
    -- ESC로 MapScene 복귀
    if key == "escape" then
        Game:getInstance().scene_manager:pop()
    end
end

return CombatScene
