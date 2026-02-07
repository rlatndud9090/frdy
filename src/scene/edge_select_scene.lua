local class = require('lib.middleclass')
local Scene = require('src.core.scene')
local EdgeSelector = require('src.ui.edge_selector')
local Game = require('src.core.game')

local EdgeSelectScene = class('EdgeSelectScene', Scene)

function EdgeSelectScene:initialize(edges, on_select_callback)
  Scene.initialize(self)

  self.edges = edges
  self.on_select_callback = on_select_callback

  -- EdgeSelector 위젯 생성 (화면 중앙에 배치)
  local screen_width = love.graphics.getWidth()
  local screen_height = love.graphics.getHeight()
  local selector_x = screen_width / 2
  local selector_y = screen_height / 2

  self.edge_selector = EdgeSelector:new(
    selector_x,
    selector_y,
    edges,
    function(edge) self:handle_edge_selected(edge) end
  )

  -- 단일 엣지인 경우 자동 진행 타이머 설정
  if #edges == 1 then
    self.auto_advance_timer = 1.0
  else
    self.auto_advance_timer = nil
  end
end

function EdgeSelectScene:enter()
  -- Scene 진입 시 호출
end

function EdgeSelectScene:update(dt)
  -- 자동 진행 타이머 처리
  if self.auto_advance_timer then
    self.auto_advance_timer = self.auto_advance_timer - dt
    if self.auto_advance_timer <= 0 then
      -- 첫 번째 엣지 자동 선택
      self:handle_edge_selected(self.edges[1])
      self.auto_advance_timer = nil
    end
  end

  -- EdgeSelector 업데이트
  self.edge_selector:update(dt)
end

function EdgeSelectScene:draw()
  -- 안내 텍스트 (화면 상단 중앙)
  local screen_width = love.graphics.getWidth()
  local text = "다음 경로를 선택하세요"
  local font = love.graphics.getFont()
  local text_width = font:getWidth(text)

  love.graphics.setColor(1, 1, 1)
  love.graphics.print(text, (screen_width - text_width) / 2, 50)

  -- EdgeSelector 그리기
  self.edge_selector:draw()
end

function EdgeSelectScene:handle_edge_selected(edge)
  -- 콜백 호출
  self.on_select_callback(edge)

  -- 자신을 Scene 스택에서 제거
  Game:getInstance().scene_manager:pop()
end

function EdgeSelectScene:mousepressed(x, y, button)
  self.edge_selector:mousepressed(x, y, button)
end

return EdgeSelectScene
