local class = require('lib.middleclass')
local Button = require('src.ui.button')
local i18n = require('src.i18n.init')

---@class Hero
---@field get_mental_stage fun(self: Hero): number
---@field can_be_controlled fun(self: Hero, max_stage: number): boolean
---@field increase_mental_load fun(self: Hero, amount: number): number
---@field get_max_mental_stage fun(self: Hero): number

---@class EventHandlerContext
---@field hero Hero|nil
---@field reward_manager RewardManager|nil
---@field spell_book SpellBook|nil
---@field mana_manager ManaManager|nil
---@field suspicion_manager SuspicionManager|nil

---@class EventHandler
---@field event Event|nil
---@field context EventHandlerContext|nil
---@field choice_buttons Button[]
---@field confirm_button Button
---@field on_event_end function|nil
---@field panel_alpha number
---@field panel_y number
---@field active boolean
---@field npc_world_x number
---@field npc_world_y number
---@field hero_choice_index number|nil
---@field selected_choice_index number|nil
---@field blink_timer number
---@field blink_on boolean
---@field feedback_text string|nil
local EventHandler = class('EventHandler')

local BLINK_INTERVAL = 0.45

---Constructor for EventHandler
function EventHandler:initialize()
  self.event = nil
  self.context = nil
  self.choice_buttons = {}
  self.confirm_button = Button:new(920, 544, 140, 35, "ui.confirm")
  self.confirm_button:set_on_click(function()
    self:_confirm_selected_choice()
  end)
  self.on_event_end = nil
  self.panel_alpha = 0
  self.panel_y = -200
  self.active = false
  self.npc_world_x = 400
  self.npc_world_y = 300
  self.hero_choice_index = nil
  self.selected_choice_index = nil
  self.blink_timer = 0
  self.blink_on = true
  self.feedback_text = nil
end

---Set the event end callback
---@param callback function
function EventHandler:set_on_event_end(callback)
  self.on_event_end = callback
end

---@return number|nil
function EventHandler:_roll_hero_choice()
  if not self.event then
    return nil
  end
  local count = self.event:get_choice_count()
  if count <= 0 then
    return nil
  end
  return math.random(count)
end

---Start a new event
---@param event Event
---@param context EventHandlerContext {hero}
function EventHandler:start_event(event, context)
  self.event = event
  self.context = context
  self.choice_buttons = {}
  self.feedback_text = nil
  self.blink_timer = 0
  self.blink_on = true
  self.hero_choice_index = self:_roll_hero_choice()
  self.selected_choice_index = self.hero_choice_index

  if not event then
    return
  end

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
      self:_on_choice_clicked(i)
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

---@return Hero|nil
function EventHandler:_get_hero()
  return self.context and self.context.hero or nil
end

---@return string
function EventHandler:_format_mental_text()
  local hero = self:_get_hero()
  if not hero then
    return i18n.t("ui.mental_stage", {stage = "?", max = 5})
  end
  return i18n.t("ui.mental_stage", {
    stage = hero:get_mental_stage(),
    max = hero:get_max_mental_stage(),
  })
end

---@return boolean
function EventHandler:_can_intervene()
  if not self.event then
    return false
  end
  local hero = self:_get_hero()
  if not hero then
    return false
  end
  return hero:can_be_controlled(self.event:get_intervention_max_mental_stage())
end

---@param index number
---@return nil
function EventHandler:_on_choice_clicked(index)
  if not self.event then
    return
  end
  if index == self.selected_choice_index then
    return
  end

  if index == self.hero_choice_index then
    self.selected_choice_index = index
    self.feedback_text = i18n.t("control.selection_reset")
    return
  end

  if not self:_can_intervene() then
    local hero = self:_get_hero()
    local hero_stage = hero and hero:get_mental_stage() or 0
    self.feedback_text = i18n.t("control.blocked_by_mental", {
      stage = hero_stage,
      max = self.event:get_intervention_max_mental_stage(),
    })
    return
  end

  self.selected_choice_index = index
  self.feedback_text = i18n.t("control.event_intervened")
end

---@param choice Choice
---@return nil
function EventHandler:_apply_intervention(choice)
  local hero = self:_get_hero()
  if not hero then
    return
  end

  hero:increase_mental_load(self.event:get_intervention_mental_increase())
end

---@return nil
function EventHandler:_confirm_selected_choice()
  if not self.event or not self.context or not self.selected_choice_index then
    return
  end

  local choice = self.event:get_choices()[self.selected_choice_index]
  if not choice then
    return
  end

  if self.hero_choice_index and self.selected_choice_index ~= self.hero_choice_index then
    self:_apply_intervention(choice)
  end

  choice:apply(self.context)

  if self.on_event_end then
    self.on_event_end()
  end
end

---Update the event handler
---@param dt number
function EventHandler:update(dt)
  if not self.active then
    return
  end

  self.blink_timer = self.blink_timer + dt
  if self.blink_timer >= BLINK_INTERVAL then
    self.blink_timer = self.blink_timer - BLINK_INTERVAL
    self.blink_on = not self.blink_on
  end

  for _, button in ipairs(self.choice_buttons) do
    button:update(dt)
  end
  self.confirm_button:update(dt)
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
  if not self.event then
    return
  end

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

  -- 조종 안내
  love.graphics.setColor(0.86, 0.88, 0.95, self.panel_alpha)
  love.graphics.print(i18n.t("ui.event_prediction_hint"), 230, 285 + self.panel_y)
  love.graphics.print(self:_format_mental_text(), 230, 308 + self.panel_y)

  if self.hero_choice_index then
    local hero_choice = self.event:get_choices()[self.hero_choice_index]
    if hero_choice then
      love.graphics.setColor(1, 0.86, 0.4, self.panel_alpha)
      love.graphics.printf(i18n.t("ui.hero_predicted_choice", {label = hero_choice:get_text()}), 230, 328 + self.panel_y, 820, "left")
    end
  end

  -- 선택지 구분선
  love.graphics.setColor(0.4, 0.4, 0.5, self.panel_alpha)
  love.graphics.line(220, 370 + self.panel_y, 1060, 370 + self.panel_y)

  -- 선택지 버튼
  for i, button in ipairs(self.choice_buttons) do
    love.graphics.push()
    love.graphics.translate(0, self.panel_y)
    love.graphics.setColor(1, 1, 1, self.panel_alpha)
    button:draw()

    local bx = button.x
    local by = button.y
    local bw = button.width
    local bh = button.height

    if i == self.selected_choice_index then
      love.graphics.setColor(0.55, 0.86, 1, self.panel_alpha)
      love.graphics.setLineWidth(2)
      love.graphics.rectangle("line", bx - 2, by - 2, bw + 4, bh + 4, 4, 4)
      love.graphics.setLineWidth(1)
    end
    if i == self.hero_choice_index and self.blink_on then
      love.graphics.setColor(1, 0.86, 0.3, self.panel_alpha)
      love.graphics.setLineWidth(2)
      love.graphics.rectangle("line", bx - 6, by - 6, bw + 12, bh + 12, 6, 6)
      love.graphics.setLineWidth(1)
    end

    love.graphics.pop()
  end

  if self.feedback_text then
    love.graphics.setColor(0.96, 0.56, 0.56, self.panel_alpha)
    love.graphics.printf(self.feedback_text, 230, 544 + self.panel_y, 650, "left")
  end

  love.graphics.push()
  love.graphics.translate(0, self.panel_y)
  self.confirm_button:draw()
  love.graphics.pop()

  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.pop()
end

---Handle mouse press events
---@param x number
---@param y number
---@param button number
function EventHandler:mousepressed(x, y, button)
  if not self.active then
    return
  end

  local adjusted_y = y - self.panel_y
  if button == 1 and self.confirm_button:hit_test(x, adjusted_y) then
    self.confirm_button:mousepressed(x, adjusted_y, button)
    return
  end

  for _, btn in ipairs(self.choice_buttons) do
    btn:mousepressed(x, adjusted_y, button)
  end
end

return EventHandler
