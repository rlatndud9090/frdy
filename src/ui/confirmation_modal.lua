local class = require('lib.middleclass')
local Button = require('src.ui.button')
local i18n = require('src.i18n.init')

---@class ConfirmationModal
---@field visible boolean
---@field title_key string
---@field body_key string
---@field body_params table|nil
---@field confirm_button Button
---@field cancel_button Button
---@field on_confirm fun(): nil
---@field on_cancel fun(): nil
local ConfirmationModal = class('ConfirmationModal')

local SCREEN_W = 1280
local SCREEN_H = 720
local PANEL_W = 420
local PANEL_H = 220

---@return nil
function ConfirmationModal:initialize()
  self.visible = false
  self.title_key = 'ui.confirm'
  self.body_key = ''
  self.body_params = nil
  self.on_confirm = function() end
  self.on_cancel = function() end

  self.cancel_button = Button:new(SCREEN_W / 2 - 140, SCREEN_H / 2 + 56, 120, 42, 'ui.cancel')
  self.cancel_button:set_visible(false)
  self.cancel_button:set_on_click(function()
    self:_cancel()
  end)

  self.confirm_button = Button:new(SCREEN_W / 2 + 20, SCREEN_H / 2 + 56, 120, 42, 'ui.confirm')
  self.confirm_button:set_visible(false)
  self.confirm_button:set_on_click(function()
    self:_confirm()
  end)
end

---@param config {title_key?: string, body_key: string, body_params?: table, confirm_label_key?: string, cancel_label_key?: string, on_confirm?: fun(): nil, on_cancel?: fun(): nil}
---@return nil
function ConfirmationModal:open(config)
  config = config or {}
  self.visible = true
  self.title_key = config.title_key or 'ui.confirm'
  self.body_key = config.body_key or ''
  self.body_params = config.body_params
  self.on_confirm = config.on_confirm or function() end
  self.on_cancel = config.on_cancel or function() end
  self.confirm_button.text = config.confirm_label_key or 'ui.confirm'
  self.cancel_button.text = config.cancel_label_key or 'ui.cancel'
  self.confirm_button:set_visible(true)
  self.cancel_button:set_visible(true)
end

---@return nil
function ConfirmationModal:close()
  self.visible = false
  self.confirm_button:set_visible(false)
  self.cancel_button:set_visible(false)
end

---@return boolean
function ConfirmationModal:is_open()
  return self.visible
end

---@return nil
function ConfirmationModal:_confirm()
  local callback = self.on_confirm
  self:close()
  callback()
end

---@return nil
function ConfirmationModal:_cancel()
  local callback = self.on_cancel
  self:close()
  callback()
end

---@param dt number
---@return nil
function ConfirmationModal:update(dt)
  if not self.visible then
    return
  end
  self.confirm_button:update(dt)
  self.cancel_button:update(dt)
end

---@return nil
function ConfirmationModal:draw()
  if not self.visible then
    return
  end

  local px = SCREEN_W / 2 - PANEL_W / 2
  local py = SCREEN_H / 2 - PANEL_H / 2

  love.graphics.setColor(0, 0, 0, 0.72)
  love.graphics.rectangle('fill', 0, 0, SCREEN_W, SCREEN_H)

  love.graphics.setColor(0.14, 0.12, 0.16, 0.98)
  love.graphics.rectangle('fill', px, py, PANEL_W, PANEL_H, 8, 8)

  love.graphics.setColor(0.58, 0.56, 0.62, 1)
  love.graphics.rectangle('line', px, py, PANEL_W, PANEL_H, 8, 8)

  love.graphics.setColor(0.96, 0.92, 0.8, 1)
  love.graphics.printf(i18n.t(self.title_key), px, py + 22, PANEL_W, 'center')

  love.graphics.setColor(0.84, 0.84, 0.9, 1)
  love.graphics.printf(i18n.t(self.body_key, self.body_params), px + 28, py + 76, PANEL_W - 56, 'center')

  self.cancel_button:draw()
  self.confirm_button:draw()
end

---@param key string
---@return nil
function ConfirmationModal:keypressed(key)
  if not self.visible then
    return
  end
  if key == 'escape' then
    self:_cancel()
    return
  end
  if key == 'return' or key == 'kpenter' or key == 'space' then
    self:_confirm()
  end
end

---@param x number
---@param y number
---@param button number
---@return nil
function ConfirmationModal:mousepressed(x, y, button)
  if not self.visible then
    return
  end
  self.cancel_button:mousepressed(x, y, button)
  self.confirm_button:mousepressed(x, y, button)
end

return ConfirmationModal
