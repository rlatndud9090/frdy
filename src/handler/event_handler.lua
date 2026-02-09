local class = require('lib.middleclass')
local Button = require('src.ui.button')

---@class EventHandler
---@field event_text string
---@field choice_buttons Button[]
---@field on_choice_callback function|nil
---@field panel_alpha number
---@field panel_y number
---@field active boolean
---@field npc_world_x number
---@field npc_world_y number
local EventHandler = class('EventHandler')

---Constructor for EventHandler
---@param params table|nil {event_text: string, choices: string[], on_choice_callback: function}
function EventHandler:initialize(params)
  params = params or {}

  self.event_text = params.event_text or "이벤트가 발생했습니다! (Placeholder)"
  local choices = params.choices or {"선택 1", "선택 2"}
  self.on_choice_callback = params.on_choice_callback

  self.panel_alpha = 0
  self.panel_y = -200
  self.active = false

  self.npc_world_x = 400
  self.npc_world_y = 300

  self.choice_buttons = {}
  local button_positions = {{x = 400, y = 400}, {x = 680, y = 400}}

  for i, choice_text in ipairs(choices) do
    local btn_x = button_positions[i].x
    local btn_y = button_positions[i].y

    self.choice_buttons[i] = Button:new(btn_x, btn_y, 200, 50, choice_text, function()
      if self.on_choice_callback then
        self.on_choice_callback(i)
      end
    end)
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
  if not self.active then
    return
  end

  for _, button in ipairs(self.choice_buttons) do
    button:update(dt)
  end
end

---Draw event NPC/object in world coordinates
function EventHandler:draw_world()
  love.graphics.push()
  love.graphics.setColor(0.6, 0.2, 0.8, self.panel_alpha)

  local diamond_size = 20
  local x = self.npc_world_x
  local y = self.npc_world_y

  love.graphics.polygon('fill',
    x, y - diamond_size,
    x + diamond_size, y,
    x, y + diamond_size,
    x - diamond_size, y
  )

  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.pop()
end

---Draw event UI panel in screen coordinates
function EventHandler:draw_ui()
  love.graphics.push()
  love.graphics.origin()

  love.graphics.setColor(0.1, 0.1, 0.1, 0.8 * self.panel_alpha)
  love.graphics.rectangle('fill', 200, 200 + self.panel_y, 880, 280)

  love.graphics.setColor(1, 1, 1, self.panel_alpha)
  love.graphics.printf(self.event_text, 200, 240 + self.panel_y, 880, 'center')

  for _, button in ipairs(self.choice_buttons) do
    love.graphics.push()
    love.graphics.translate(0, self.panel_y)
    love.graphics.setColor(1, 1, 1, self.panel_alpha)
    button:draw()
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
  if not self.active then
    return
  end

  local adjusted_y = y - self.panel_y

  for _, btn in ipairs(self.choice_buttons) do
    btn:mousepressed(x, adjusted_y, button)
  end
end

---Set the choice callback function
---@param callback function
function EventHandler:set_on_choice(callback)
  self.on_choice_callback = callback
end

return EventHandler
