local class = require('lib.middleclass')
local Scene = require('src.core.scene')
local Button = require('src.ui.button')
local FontManager = require('src.core.font_manager')
local Game = require('src.core.game')
local i18n = require('src.i18n.init')

---@class RunEndSummary
---@field floor number
---@field level number

---@class RunEndScene : Scene
---@field reason string
---@field summary RunEndSummary
---@field menu_button Button
local RunEndScene = class('RunEndScene', Scene)

local SCREEN_W = 1280
local SCREEN_H = 720

---@param options? {reason?: string, summary?: RunEndSummary}
---@return nil
function RunEndScene:initialize(options)
  Scene.initialize(self)
  options = options or {}
  self.reason = options.reason or 'death'
  self.summary = options.summary or {floor = 1, level = 1}
  self.menu_button = Button:new(SCREEN_W * 0.5 - 130, 470, 260, 48, 'ui.back_to_main_menu')
  self.menu_button:set_on_click(function()
    local MainMenuScene = require('src.scene.main_menu_scene')
    Game:getInstance():switch_scene(MainMenuScene:new())
  end)
end

---@return string
function RunEndScene:_resolve_title_key()
  if self.reason == 'victory' then
    return 'ui.run_cleared'
  end
  if self.reason == 'abandon' then
    return 'ui.run_abandoned'
  end
  return 'ui.run_ended'
end

---@return string
function RunEndScene:_resolve_reason_key()
  if self.reason == 'victory' then
    return 'ui.run_victory_reason'
  end
  if self.reason == 'abandon' then
    return 'ui.run_abandon_reason'
  end
  return 'ui.run_death_reason'
end

---@param dt number
---@return nil
function RunEndScene:update(dt)
  self.menu_button:update(dt)
end

---@return nil
function RunEndScene:draw()
  love.graphics.clear(0.04, 0.03, 0.05, 1)
  love.graphics.setColor(0.1, 0.05, 0.08, 1)
  love.graphics.rectangle('fill', 0, 0, SCREEN_W, SCREEN_H)

  love.graphics.setColor(0.14, 0.1, 0.14, 0.96)
  love.graphics.rectangle('fill', 260, 120, 760, 470, 10, 10)
  love.graphics.setColor(0.56, 0.42, 0.28, 1)
  love.graphics.rectangle('line', 260, 120, 760, 470, 10, 10)

  local previous_font = love.graphics.getFont()
  love.graphics.setFont(FontManager.get('title'))
  love.graphics.setColor(0.96, 0.85, 0.72, 1)
  love.graphics.printf(i18n.t(self:_resolve_title_key()), 260, 180, 760, 'center')

  love.graphics.setFont(FontManager.get('large'))
  love.graphics.setColor(0.86, 0.86, 0.92, 1)
  love.graphics.printf(i18n.t(self:_resolve_reason_key()), 260, 250, 760, 'center')

  love.graphics.setFont(FontManager.get('medium'))
  love.graphics.setColor(0.72, 0.72, 0.8, 1)
  love.graphics.printf(
    i18n.t('ui.run_summary', {
      floor = self.summary.floor or 1,
      level = self.summary.level or 1,
    }),
    260,
    320,
    760,
    'center'
  )

  self.menu_button:draw()
  love.graphics.setFont(previous_font)
end

---@param key string
---@return nil
function RunEndScene:keypressed(key)
  if key == 'return' or key == 'escape' or key == 'space' then
    self.menu_button:on_click()
  end
end

---@param x number
---@param y number
---@param button number
---@return nil
function RunEndScene:mousepressed(x, y, button)
  self.menu_button:mousepressed(x, y, button)
end

return RunEndScene
