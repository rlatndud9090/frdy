local class = require('lib.middleclass')
local Scene = require("src.scene.scene")
local Button = require("src.ui.button")
local SceneManager = require("src.core.scene_manager")

local EventScene = class('EventScene', Scene)

function EventScene:initialize()
    Scene.initialize(self)

    self.event_text = "이벤트가 발생했습니다! (Placeholder)"
    self.choice_buttons = {}

    -- 선택 1 버튼 (MapScene 복귀)
    local button1 = Button.new(400, 400, 200, 50, "선택 1")
    button1:set_on_click(function()
        SceneManager:change_scene("map")
    end)
    table.insert(self.choice_buttons, button1)

    -- 선택 2 버튼 (MapScene 복귀)
    local button2 = Button.new(680, 400, 200, 50, "선택 2")
    button2:set_on_click(function()
        SceneManager:change_scene("map")
    end)
    table.insert(self.choice_buttons, button2)
end

function EventScene:enter(params)
    -- 진입 시 초기화
    self:initialize()
end

function EventScene:update(dt)
    -- 버튼들 업데이트
    for _, button in ipairs(self.choice_buttons) do
        button:update(dt)
    end
end

function EventScene:draw()
    -- 배경
    love.graphics.setColor(0.2, 0.2, 0.2)
    love.graphics.rectangle("fill", 0, 0, 1280, 720)

    -- event_text 표시
    love.graphics.setColor(1, 1, 1)
    love.graphics.printf(self.event_text, 0, 200, 1280, "center")

    -- 버튼들 그리기
    for _, button in ipairs(self.choice_buttons) do
        button:draw()
    end
end

function EventScene:mousepressed(x, y, button)
    -- 버튼들에 마우스 이벤트 전달
    for _, btn in ipairs(self.choice_buttons) do
        btn:mousepressed(x, y, button)
    end
end

function EventScene:keypressed(key)
    -- ESC로 MapScene 복귀
    if key == "escape" then
        SceneManager:change_scene("map")
    end
end

return EventScene
