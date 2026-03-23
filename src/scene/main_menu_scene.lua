local class = require('lib.middleclass')
local Scene = require('src.core.scene')
local Button = require('src.ui.button')
local ConfirmationModal = require('src.ui.confirmation_modal')
local SettingsOverlay = require('src.ui.settings_overlay')
local FontManager = require('src.core.font_manager')
local RunSave = require('src.core.run_save')
local Game = require('src.core.game')
local i18n = require('src.i18n.init')

---@class MainMenuScene : Scene
---@field buttons Button[]
---@field confirmation_modal ConfirmationModal
---@field settings_overlay SettingsOverlay
---@field feedback_text string|nil
---@field has_continue boolean
---@field suppress_continue boolean
local MainMenuScene = class('MainMenuScene', Scene)

local SCREEN_W = 1280
local SCREEN_H = 720

---@param label_key string
---@param callback fun(): nil
---@return Button
function MainMenuScene:_create_button(label_key, callback)
  local button = Button:new(0, 0, 260, 48, label_key)
  button:set_on_click(callback)
  return button
end

---@param options? {suppress_continue?: boolean, feedback_text?: string}
---@return nil
function MainMenuScene:initialize(options)
  Scene.initialize(self)
  options = options or {}
  self.buttons = {}
  self.confirmation_modal = ConfirmationModal:new()
  self.settings_overlay = SettingsOverlay:new()
  self.feedback_text = options.feedback_text
  self.has_continue = false
  self.suppress_continue = options.suppress_continue == true
  self:_rebuild_buttons()
end

---@return nil
function MainMenuScene:_rebuild_buttons()
  self.buttons = {}
  self.has_continue = (not self.suppress_continue) and RunSave:exists()

  if self.has_continue then
    self.buttons[#self.buttons + 1] = self:_create_button('ui.continue_run', function()
      self:_continue_run()
    end)
  end

  self.buttons[#self.buttons + 1] = self:_create_button('ui.new_game', function()
    self:_start_new_game()
  end)
  self.buttons[#self.buttons + 1] = self:_create_button('ui.settings', function()
    self.settings_overlay:open()
  end)
  self.buttons[#self.buttons + 1] = self:_create_button('ui.collection', function()
    self.feedback_text = i18n.t('ui.coming_soon')
  end)
  self.buttons[#self.buttons + 1] = self:_create_button('ui.statistics', function()
    self.feedback_text = i18n.t('ui.coming_soon')
  end)
  self.buttons[#self.buttons + 1] = self:_create_button('ui.quit_game', function()
    love.event.quit()
  end)

  local total_h = #self.buttons * 48 + math.max(0, #self.buttons - 1) * 14
  local start_y = 280 - total_h * 0.5
  for index, button in ipairs(self.buttons) do
    button:set_position(SCREEN_W * 0.5 - button.width * 0.5, start_y + (index - 1) * 62)
  end
end

---@return nil
function MainMenuScene:_start_new_game()
  local function begin_new_run()
    local GameScene = require('src.scene.game_scene')
    local ok, scene_or_err = pcall(function()
      return GameScene:new()
    end)
    if not ok then
      print(scene_or_err)
      self.feedback_text = i18n.t('ui.run_start_failed')
      self:_rebuild_buttons()
      return
    end

    if self.has_continue then
      local cleared, clear_err = RunSave:clear()
      if not cleared then
        print(clear_err)
        local invalidated, invalidate_err = RunSave:invalidate('new_game_start')
        if not invalidated and invalidate_err then
          print(invalidate_err)
        end
      end
    end

    Game:getInstance():switch_scene(scene_or_err)
  end

  if self.has_continue then
    self.confirmation_modal:open({
      title_key = 'ui.new_game',
      body_key = 'ui.confirm_overwrite_save',
      confirm_label_key = 'ui.new_game',
      cancel_label_key = 'ui.cancel',
      on_confirm = function()
        begin_new_run()
      end,
    })
    return
  end

  begin_new_run()
end

---@param invalidate_save boolean
---@return nil
function MainMenuScene:_handle_continue_failure(invalidate_save)
  if invalidate_save then
    local invalidated, invalidate_err = RunSave:invalidate('load_failed')
    if not invalidated and invalidate_err then
      print(invalidate_err)
    end
    self.suppress_continue = true
  end

  self.feedback_text = i18n.t('ui.save_load_failed')
  self:_rebuild_buttons()
end

---@return nil
function MainMenuScene:_continue_run()
  local payload, err = RunSave:load()
  if not payload then
    if err then
      print(err)
    end
    self:_handle_continue_failure(true)
    return
  end

  local GameScene = require('src.scene.game_scene')
  local ok, scene_or_err = pcall(function()
    return GameScene:new({
      save_data = payload,
    })
  end)
  if not ok then
    print(scene_or_err)
    self:_handle_continue_failure(false)
    return
  end

  Game:getInstance():switch_scene(scene_or_err)
end

---@param dt number
---@return nil
function MainMenuScene:update(dt)
  self.confirmation_modal:update(dt)
  for _, button in ipairs(self.buttons) do
    button:update(dt)
  end
  self.settings_overlay:update(dt)
end

---@return nil
function MainMenuScene:draw()
  love.graphics.clear(0.06, 0.05, 0.08, 1)

  love.graphics.setColor(0.16, 0.12, 0.18, 1)
  love.graphics.rectangle('fill', 0, 0, SCREEN_W, SCREEN_H)
  love.graphics.setColor(0.3, 0.18, 0.1, 0.2)
  love.graphics.circle('fill', 180, 120, 220)
  love.graphics.setColor(0.08, 0.1, 0.18, 0.28)
  love.graphics.circle('fill', 1080, 620, 260)

  local previous_font = love.graphics.getFont()
  love.graphics.setFont(FontManager.get('title'))
  love.graphics.setColor(0.96, 0.9, 0.72, 1)
  love.graphics.printf(i18n.t('ui.game_title'), 0, 110, SCREEN_W, 'center')

  love.graphics.setFont(FontManager.get('medium'))
  love.graphics.setColor(0.82, 0.82, 0.9, 1)
  love.graphics.printf(i18n.t('ui.main_menu_subtitle'), 0, 154, SCREEN_W, 'center')

  for _, button in ipairs(self.buttons) do
    button:draw()
  end

  if self.feedback_text then
    love.graphics.setColor(0.95, 0.68, 0.52, 1)
    love.graphics.printf(self.feedback_text, 0, 540, SCREEN_W, 'center')
  end

  love.graphics.setColor(0.62, 0.62, 0.7, 1)
  love.graphics.printf(i18n.t('ui.menu_hint'), 0, 668, SCREEN_W, 'center')

  love.graphics.setFont(previous_font)
  self.settings_overlay:draw()
  self.confirmation_modal:draw()
end

---@param key string
---@return nil
function MainMenuScene:keypressed(key)
  if self.confirmation_modal:is_open() then
    self.confirmation_modal:keypressed(key)
    return
  end

  if self.settings_overlay:is_open() then
    self.settings_overlay:keypressed(key)
    return
  end

  if key == 'escape' or key == 'tab' then
    self.settings_overlay:open()
  end
end

---@param x number
---@param y number
---@param button number
---@return nil
function MainMenuScene:mousepressed(x, y, button)
  if self.confirmation_modal:is_open() then
    self.confirmation_modal:mousepressed(x, y, button)
    return
  end

  if self.settings_overlay:is_open() then
    self.settings_overlay:mousepressed(x, y, button)
    return
  end

  for _, menu_button in ipairs(self.buttons) do
    menu_button:mousepressed(x, y, button)
  end
end

return MainMenuScene
