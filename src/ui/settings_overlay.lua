local class = require("lib.middleclass")
local flux = require("lib.flux")
local Button = require("src.ui.button")
local Dropdown = require("src.ui.dropdown")
local i18n = require("src.i18n.init")

---@class SettingsOverlay
---@field visible boolean
---@field is_closing boolean
---@field alpha number
---@field close_button Button
---@field language_dropdown Dropdown
local SettingsOverlay = class("SettingsOverlay")

local SCREEN_W = 1280
local SCREEN_H = 720
local PANEL_W = 500
local PANEL_H = 300

function SettingsOverlay:initialize()
  self.visible = false
  self.is_closing = false
  self.alpha = 0

  self.close_button = Button:new(SCREEN_W / 2 + PANEL_W / 2 - 70, SCREEN_H / 2 - PANEL_H / 2 + 10, 60, 30, "ui.close")
  self.close_button:set_visible(false)
  self.close_button:set_on_click(function()
    self:close()
  end)

  -- Language dropdown
  local locales = i18n.get_available_locales()
  self.language_dropdown = Dropdown:new(
    SCREEN_W / 2 + 10, SCREEN_H / 2 - 30,
    180, 35,
    locales,
    i18n.get_locale()
  )
  self.language_dropdown:set_visible(false)
  self.language_dropdown:set_on_change(function(key)
    i18n.set_locale(key)
  end)
end

function SettingsOverlay:open()
  if self.visible then return end
  self.visible = true
  self.alpha = 0
  self.close_button:set_visible(true)
  self.language_dropdown:set_visible(true)

  -- Refresh dropdown options
  local locales = i18n.get_available_locales()
  self.language_dropdown:set_options(locales, i18n.get_locale())

  flux.to(self, 0.3, {alpha = 1}):ease("quadout")
end

function SettingsOverlay:close()
  if not self.visible or self.is_closing then return end
  self.is_closing = true

  flux.to(self, 0.2, {alpha = 0})
    :ease("quadin")
    :oncomplete(function()
      self.visible = false
      self.is_closing = false
      self.close_button:set_visible(false)
      self.language_dropdown:set_visible(false)
    end)
end

---@return boolean
function SettingsOverlay:is_open()
  return self.visible
end

---@param dt number
function SettingsOverlay:update(dt)
  if not self.visible then return end
  self.close_button:update(dt)
  self.language_dropdown:update(dt)
end

function SettingsOverlay:draw()
  if not self.visible then return end

  -- Dark background
  love.graphics.setColor(0, 0, 0, 0.85 * self.alpha)
  love.graphics.rectangle("fill", 0, 0, SCREEN_W, SCREEN_H)

  -- Panel
  local px = SCREEN_W / 2 - PANEL_W / 2
  local py = SCREEN_H / 2 - PANEL_H / 2

  love.graphics.setColor(0.12, 0.12, 0.18, 0.95 * self.alpha)
  love.graphics.rectangle("fill", px, py, PANEL_W, PANEL_H, 8, 8)

  love.graphics.setColor(0.5, 0.5, 0.6, self.alpha)
  love.graphics.rectangle("line", px, py, PANEL_W, PANEL_H, 8, 8)

  -- Title
  love.graphics.setColor(1, 1, 1, self.alpha)
  love.graphics.printf(i18n.t("ui.settings"), px, py + 15, PANEL_W, "center")

  -- Divider
  love.graphics.setColor(0.4, 0.4, 0.5, self.alpha)
  love.graphics.line(px + 20, py + 50, px + PANEL_W - 20, py + 50)

  -- Language label
  love.graphics.setColor(0.9, 0.9, 0.9, self.alpha)
  local label_x = SCREEN_W / 2 - PANEL_W / 2 + 30
  local label_y = SCREEN_H / 2 - 22
  love.graphics.print(i18n.t("ui.language") .. ":", label_x, label_y)

  -- Dropdown and close button
  self.language_dropdown:draw()
  self.close_button:draw()

  -- Hint
  love.graphics.setColor(0.6, 0.6, 0.6, self.alpha)
  love.graphics.printf("Tab / ESC", px, py + PANEL_H - 30, PANEL_W, "center")
end

---@param key string
function SettingsOverlay:keypressed(key)
  if not self.visible then return end
  if key == "escape" or key == "tab" then
    self:close()
  end
end

---@param mx number
---@param my number
---@param button number
function SettingsOverlay:mousepressed(mx, my, button)
  if not self.visible then return end
  self.language_dropdown:mousepressed(mx, my, button)
  self.close_button:mousepressed(mx, my, button)
end

return SettingsOverlay
