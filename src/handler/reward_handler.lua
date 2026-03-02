local class = require('lib.middleclass')
local Button = require('src.ui.button')
local i18n = require('src.i18n.init')
local RNG = require('src.core.rng')

---@class Hero
---@field get_mental_stage fun(self: Hero): number
---@field get_max_mental_stage fun(self: Hero): number
---@field can_be_controlled fun(self: Hero, max_stage: number): boolean
---@field increase_mental_load fun(self: Hero, amount: number): number

---@class RewardOption
---@field display_text string
---@field description string|nil

---@class RewardOffer
---@field title_key string
---@field options RewardOption[]
---@field control {max_stage: number, mental_increase: number}

---@class RewardHandler
---@field offer RewardOffer|nil
---@field hero Hero|nil
---@field option_buttons Button[]
---@field confirm_button Button
---@field hero_choice_index number|nil
---@field selected_choice_index number|nil
---@field blink_timer number
---@field blink_on boolean
---@field feedback_text string|nil
---@field active boolean
---@field on_resolved fun(selected_option: RewardOption|nil)|nil
---@field rng RNG
local RewardHandler = class('RewardHandler')

local BLINK_INTERVAL = 0.45

---@param rng? RNG
---@return nil
function RewardHandler:initialize(rng)
  self.offer = nil
  self.hero = nil
  self.option_buttons = {}
  self.confirm_button = Button:new(920, 592, 140, 38, 'ui.confirm')
  self.confirm_button:set_on_click(function()
    self:_confirm_selected_choice()
  end)
  self.hero_choice_index = nil
  self.selected_choice_index = nil
  self.blink_timer = 0
  self.blink_on = true
  self.feedback_text = nil
  self.active = false
  self.on_resolved = nil
  self.rng = rng or RNG:new(os.time())
end

---@param rng RNG
---@return nil
function RewardHandler:set_rng(rng)
  self.rng = rng
end

---@param offer RewardOffer
---@param context {hero: Hero|nil}
---@param on_resolved fun(selected_option: RewardOption|nil)
---@return nil
function RewardHandler:start_offer(offer, context, on_resolved)
  self.offer = offer
  self.hero = context and context.hero or nil
  self.on_resolved = on_resolved
  self.option_buttons = {}
  self.feedback_text = nil
  self.blink_timer = 0
  self.blink_on = true
  self.hero_choice_index = self:_roll_hero_choice()
  self.selected_choice_index = self.hero_choice_index

  local panel_x = 180
  local button_y_start = 350
  local button_height = 52
  local button_spacing = 12

  for i, option in ipairs(offer.options or {}) do
    local btn_y = button_y_start + (i - 1) * (button_height + button_spacing)
    local btn = Button:new(panel_x + 20, btn_y, 880, button_height, option.display_text)
    btn:set_on_click(function()
      self:_on_choice_clicked(i)
    end)
    table.insert(self.option_buttons, btn)
  end

  self.active = true
end

---@return nil
function RewardHandler:deactivate()
  self.active = false
end

---@return number|nil
function RewardHandler:_roll_hero_choice()
  if not self.offer then
    return nil
  end
  local count = #(self.offer.options or {})
  if count <= 0 then
    return nil
  end
  return self.rng:next_int(1, count)
end

---@return Hero|nil
function RewardHandler:_get_hero()
  return self.hero
end

---@return boolean
function RewardHandler:_can_intervene()
  local offer = self.offer
  local hero = self:_get_hero()
  if not offer or not hero then
    return false
  end
  local control = offer.control or {max_stage = 3}
  return hero:can_be_controlled(control.max_stage or 3)
end

---@return string
function RewardHandler:_format_mental_text()
  local hero = self:_get_hero()
  if not hero then
    return i18n.t('ui.mental_stage', {stage = '?', max = 5})
  end
  return i18n.t('ui.mental_stage', {
    stage = hero:get_mental_stage(),
    max = hero:get_max_mental_stage(),
  })
end

---@param index number
---@return nil
function RewardHandler:_on_choice_clicked(index)
  if not self.offer then
    return
  end
  if index == self.selected_choice_index then
    return
  end

  if index == self.hero_choice_index then
    self.selected_choice_index = index
    self.feedback_text = i18n.t('control.selection_reset')
    return
  end

  if not self:_can_intervene() then
    local hero = self:_get_hero()
    local hero_stage = hero and hero:get_mental_stage() or 0
    local max_stage = (self.offer.control and self.offer.control.max_stage) or 3
    self.feedback_text = i18n.t('control.blocked_by_mental', {
      stage = hero_stage,
      max = max_stage,
    })
    return
  end

  self.selected_choice_index = index
  self.feedback_text = i18n.t('control.reward_intervened')
end

---@return nil
function RewardHandler:_apply_intervention_if_needed()
  if not self.offer then
    return
  end
  if not self.hero_choice_index or not self.selected_choice_index then
    return
  end
  if self.hero_choice_index == self.selected_choice_index then
    return
  end

  local hero = self:_get_hero()
  if not hero then
    return
  end

  local control = self.offer.control or {mental_increase = 0.25}
  hero:increase_mental_load(control.mental_increase or 0.25)
end

---@return nil
function RewardHandler:_confirm_selected_choice()
  if not self.offer or not self.selected_choice_index then
    return
  end

  local selected_option = self.offer.options[self.selected_choice_index]
  if not selected_option then
    return
  end

  self:_apply_intervention_if_needed()

  local callback = self.on_resolved
  self.active = false
  self.offer = nil
  self.option_buttons = {}
  if callback then
    callback(selected_option)
  end
end

---@param dt number
---@return nil
function RewardHandler:update(dt)
  if not self.active then
    return
  end

  self.blink_timer = self.blink_timer + dt
  if self.blink_timer >= BLINK_INTERVAL then
    self.blink_timer = self.blink_timer - BLINK_INTERVAL
    self.blink_on = not self.blink_on
  end

  for _, button in ipairs(self.option_buttons) do
    button:update(dt)
  end
  self.confirm_button:update(dt)
end

---@param i number
---@param button Button
---@return nil
function RewardHandler:_draw_option_frame(i, button)
  local is_selected = i == self.selected_choice_index
  local is_hero = i == self.hero_choice_index and self.blink_on

  if is_selected and is_hero then
    love.graphics.setColor(1, 0.87, 0.45, 0.95)
  elseif is_selected then
    love.graphics.setColor(0.35, 0.75, 1, 0.95)
  elseif is_hero then
    love.graphics.setColor(1, 0.75, 0.2, 0.8)
  else
    return
  end

  love.graphics.setLineWidth(3)
  love.graphics.rectangle('line', button.x - 2, button.y - 2, button.width + 4, button.height + 4, 5, 5)
  love.graphics.setLineWidth(1)
end

---@return nil
function RewardHandler:draw()
  if not self.active or not self.offer then
    return
  end

  love.graphics.setColor(0, 0, 0, 0.65)
  love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())

  local panel_x = 160
  local panel_y = 170
  local panel_w = 960
  local panel_h = 470

  love.graphics.setColor(0.12, 0.12, 0.16, 0.96)
  love.graphics.rectangle('fill', panel_x, panel_y, panel_w, panel_h, 10, 10)
  love.graphics.setColor(0.66, 0.62, 0.75, 0.95)
  love.graphics.rectangle('line', panel_x, panel_y, panel_w, panel_h, 10, 10)

  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.printf(i18n.t('ui.settlement_title'), panel_x, panel_y + 22, panel_w, 'center')

  local reward_name = i18n.t(self.offer.title_key or 'reward.unknown')
  love.graphics.setColor(0.9, 0.9, 1, 1)
  love.graphics.printf(i18n.t('ui.reward_choose', {category = reward_name}), panel_x, panel_y + 64, panel_w, 'center')

  love.graphics.setColor(0.86, 0.86, 0.94, 1)
  love.graphics.print(self:_format_mental_text(), panel_x + 36, panel_y + 100)

  if self.hero_choice_index and self.offer.options[self.hero_choice_index] then
    love.graphics.setColor(1, 0.86, 0.4, 1)
    love.graphics.print(
      i18n.t('ui.reward_predicted_choice', {label = self.offer.options[self.hero_choice_index].display_text}),
      panel_x + 36,
      panel_y + 128
    )
  end

  if self.feedback_text then
    love.graphics.setColor(0.96, 0.56, 0.56, 1)
    love.graphics.print(self.feedback_text, panel_x + 36, panel_y + 156)
  end

  for i, button in ipairs(self.option_buttons) do
    button:draw()
    self:_draw_option_frame(i, button)

    local option = self.offer.options[i]
    if option and option.description then
      love.graphics.setColor(0.7, 0.72, 0.8, 1)
      love.graphics.printf(option.description, button.x, button.y + button.height + 3, button.width, 'left')
    end
  end

  self.confirm_button:draw()
end

---@param x number
---@param y number
---@param button number
---@return nil
function RewardHandler:mousepressed(x, y, button)
  if not self.active then
    return
  end

  if button == 1 and self.confirm_button:hit_test(x, y) then
    self.confirm_button:mousepressed(x, y, button)
    return
  end

  for _, option_button in ipairs(self.option_buttons) do
    option_button:mousepressed(x, y, button)
  end
end

return RewardHandler
