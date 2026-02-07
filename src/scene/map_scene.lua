local class = require('lib.middleclass')
local Scene = require("src.scene.scene")
local Map = require("src.map.map")
local MapGenerator = require("src.map.map_generator")
local Gauge = require("src.ui.gauge")
local Button = require("src.ui.button")

local MapScene = class('MapScene', Scene)

local SEGMENT_WIDTH = 300

function MapScene:initialize()
    MapScene.__super.initialize(self)

    -- 맵 및 좌표계
    self.map = nil
    self.hero_world_x = 0
    self.camera_offset_x = 0
    self.current_column = 0

    -- UI 위젯
    self.suspicion_gauge = nil
    self.mana_gauge = nil
    self.minimap_button = nil

    -- MapGenerator로 맵 생성
    local generator = MapGenerator.new()
    self.map = generator:generate()

    -- 용사를 시작 노드에 배치 (column 0)
    self.current_column = 0
    self.hero_world_x = self.current_column * SEGMENT_WIDTH

    -- UI 위젯 생성
    -- 의심 게이지 (화면 왼쪽 상단)
    self.suspicion_gauge = Gauge.new(20, 20, 200, 30, "의심", {1, 0, 0})
    self.suspicion_gauge:set_value(0)
    self.suspicion_gauge:set_max(100)

    -- 마나 게이지 (의심 게이지 아래)
    self.mana_gauge = Gauge.new(20, 60, 200, 30, "마나", {0, 0.5, 1})
    self.mana_gauge:set_value(100)
    self.mana_gauge:set_max(100)

    -- 미니맵 버튼 (화면 오른쪽 상단)
    self.minimap_button = Button.new(1280 - 120, 20, 100, 40, "미니맵")
    self.minimap_button:set_on_click(function()
        print("미니맵 버튼 클릭됨")
        -- TODO: 미니맵 씬으로 전환
    end)
end

function MapScene:enter()
    -- 진입 시 특정 상태만 리셋 (전체 초기화는 필요 없음)
end

function MapScene:update(dt)
    -- 카메라 오프셋 업데이트 (용사를 화면 중앙에 위치)
    self.camera_offset_x = self.hero_world_x - 640

    -- UI 위젯 업데이트
    self.suspicion_gauge:update(dt)
    self.mana_gauge:update(dt)
    self.minimap_button:update(dt)
end

function MapScene:draw()
    -- 카메라 오프셋 적용
    love.graphics.push()
    love.graphics.translate(-self.camera_offset_x, 0)

    -- 현재 노드 표시 (placeholder)
    -- 현재 열의 월드 좌표
    local node_world_x = self.current_column * SEGMENT_WIDTH
    local node_y = 360 -- 화면 중앙 높이

    -- 노드 원으로 표시
    love.graphics.setColor(0.3, 0.3, 0.8, 1)
    love.graphics.circle("fill", node_world_x, node_y, 40)

    -- 노드 외곽선
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.circle("line", node_world_x, node_y, 40)

    -- 용사 위치 표시
    love.graphics.setColor(1, 0.8, 0, 1)
    love.graphics.circle("fill", self.hero_world_x, node_y - 60, 20)

    -- 용사 외곽선
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.circle("line", self.hero_world_x, node_y - 60, 20)

    -- 그리드 참조선 (디버깅용)
    love.graphics.setColor(0.5, 0.5, 0.5, 0.3)
    for i = -2, 5 do
        local x = (self.current_column + i) * SEGMENT_WIDTH
        love.graphics.line(x, 0, x, 720)
    end

    love.graphics.pop()

    -- UI 위젯 그리기 (카메라 영향 없음)
    love.graphics.setColor(1, 1, 1, 1)
    self.suspicion_gauge:draw()
    self.mana_gauge:draw()
    self.minimap_button:draw()
end

function MapScene:keypressed(key)
    if key == "escape" then
        love.event.quit()
    end

    -- 디버그: 좌우 화살표로 열 이동
    if key == "right" then
        self.current_column = self.current_column + 1
        self.hero_world_x = self.current_column * SEGMENT_WIDTH
    elseif key == "left" and self.current_column > 0 then
        self.current_column = self.current_column - 1
        self.hero_world_x = self.current_column * SEGMENT_WIDTH
    end
end

function MapScene:mousepressed(x, y, button)
    -- UI 위젯에 마우스 이벤트 전달
    self.suspicion_gauge:mousepressed(x, y, button)
    self.mana_gauge:mousepressed(x, y, button)
    self.minimap_button:mousepressed(x, y, button)
end

return MapScene
