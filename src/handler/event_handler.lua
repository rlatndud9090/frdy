local class = require('lib.middleclass')
local Button = require('src.ui.button')
local i18n = require('src.i18n.init')

---@class EventHandler
---@field event Event|nil
---@field context table|nil -- {hero, suspicion_manager}
---@field choice_buttons Button[]
---@field on_event_end function|nil
---@field panel_alpha number
---@field panel_y number
---@field active boolean
---@field npc_world_x number
---@field npc_world_y number
local EventHandler = class('EventHandler')

---Constructor for EventHandler
function EventHandler:initialize()
  self.event = nil
  self.context = nil
  self.choice_buttons = {}
  self.on_event_end = nil
  self.panel_alpha = 0
  self.panel_y = -200
  self.active = false
  self.npc_world_x = 400
  self.npc_world_y = 300
end

---Set the event end callback
---@param callback function
function EventHandler:set_on_event_end(callback)
  self.on_event_end = callback
end

---Start a new event
---@param event Event
---@param context table {hero, suspicion_manager}
function EventHandler:start_event(event, context)
  self.event = event
  self.context = context
  self.choice_buttons = {}

  if not event then return end

  local choices = event:get_choices()

  -- 선택지 버튼 생성 (수직 배치, 패널 내부)
  local panel_x = 200
  local button_y_start = 380
  local button_height = 45
  local button_spacing = 10

  for i, choice in ipairs(choices) do
    local btn_y = button_y_start + (i - 1) * (button_height + button_spacing)
    local btn_text = choice:get_text()

    local btn = Button:new(panel_x + 20, btn_y, 840, button_height, btn_text)
    btn:set_on_click(function()
      self:_on_choice_selected(i)
    end)
    table.insert(self.choice_buttons, btn)
  end
end

---Activate the event handler
function EventHandler:activate()
  self.active = true
end

---Deactivate the event handler
function EventHandler:deactivate()
  self.active = false
end

---Update the event handler
---@param dt number
function EventHandler:update(dt)
  if not self.active then return end
  for _, button in ipairs(self.choice_buttons) do
    button:update(dt)
  end
end

---Draw event NPC/object in world coordinates
function EventHandler:draw_world()
  -- NPC/이벤트 오브젝트 (보라색 다이아몬드)
  love.graphics.setColor(0.6, 0.2, 0.8, self.panel_alpha)
  local x = self.npc_world_x
  local y = self.npc_world_y
  local size = 20
  love.graphics.polygon('fill', x, y - size, x + size, y, x, y + size, x - size, y)
  love.graphics.setColor(1, 1, 1, 1)
end

---Draw event UI panel in screen coordinates
function EventHandler:draw_ui()
  if not self.event then return end

  love.graphics.push()
  love.graphics.origin()

  -- 이벤트 패널 배경
  love.graphics.setColor(0.1, 0.1, 0.15, 0.9 * self.panel_alpha)
  love.graphics.rectangle('fill', 200, 180 + self.panel_y, 880, 360, 8, 8)

  -- 패널 테두리
  love.graphics.setColor(0.5, 0.4, 0.7, self.panel_alpha)
  love.graphics.rectangle('line', 200, 180 + self.panel_y, 880, 360, 8, 8)

  -- 이벤트 제목
  love.graphics.setColor(1, 0.9, 0.5, self.panel_alpha)
  love.graphics.printf(self.event:get_title(), 220, 200 + self.panel_y, 840, 'center')

  -- 이벤트 설명
  love.graphics.setColor(0.9, 0.9, 0.9, self.panel_alpha)
  love.graphics.printf(self.event:get_description(), 220, 240 + self.panel_y, 840, 'center')

  -- 선택지 구분선
  love.graphics.setColor(0.4, 0.4, 0.5, self.panel_alpha)
  love.graphics.line(220, 370 + self.panel_y, 1060, 370 + self.panel_y)

  -- 선택지 버튼
  for i, button in ipairs(self.choice_buttons) do
    love.graphics.push()
    love.graphics.translate(0, self.panel_y)
    love.graphics.setColor(1, 1, 1, self.panel_alpha)
    button:draw()

    -- 의심도 변동 표시 (버튼 오른쪽)
    if self.event then
      local choices = self.event:get_choices()
      if choices[i] then
        local susp = choices[i]:get_suspicion_delta()
        if susp > 0 then
          love.graphics.setColor(1, 0.3, 0.3, self.panel_alpha)
          love.graphics.print(i18n.t("suspicion.increase", {value = susp}), 1070, button.y + 12)
        elseif susp < 0 then
          love.graphics.setColor(0.3, 1, 0.3, self.panel_alpha)
          love.graphics.print(i18n.t("suspicion.decrease", {value = susp}), 1070, button.y + 12)
        end
      end
    end

    love.graphics.pop()
  end

  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.pop()
end

---Handle mouse press events
---@param x number
---@param y number
---@param button number
function EventHandler:mousepressed(x, y, button)
  if not self.active then return end
  local adjusted_y = y - self.panel_y
  for _, btn in ipairs(self.choice_buttons) do
    btn:mousepressed(x, adjusted_y, button)
  end
end

---Internal callback when a choice is selected
---@param index number
function EventHandler:_on_choice_selected(index)
  if not self.event or not self.context then return end

  local choices = self.event:get_choices()
  local choice = choices[index]
  if choice then
    choice:apply(self.context)
  end

  if self.on_event_end then
    self.on_event_end()
  end
end

return EventHandler
