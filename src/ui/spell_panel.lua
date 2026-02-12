local class = require("lib.middleclass")
local UIElement = require("src.ui.ui_element")
local i18n = require("src.i18n.init")

---@class SpellPanel : UIElement
---@field spells Spell[]
---@field mana_manager ManaManager|nil
---@field on_play_callback function|nil  -- function(spell, index)
---@field on_pass_callback function|nil  -- function()
---@field hovered_index number|nil
---@field spell_width number
---@field spell_height number
---@field spell_spacing number
local SpellPanel = class("SpellPanel", UIElement)

function SpellPanel:initialize()
  UIElement.initialize(self, 0, 0, 1280, 200)
  self.spells = {}
  self.mana_manager = nil
  self.on_play_callback = nil
  self.on_pass_callback = nil
  self.hovered_index = nil
  self.spell_width = 120
  self.spell_height = 160
  self.spell_spacing = 10
end

function SpellPanel:set_spells(spells)
  self.spells = spells or {}
end

function SpellPanel:set_mana_manager(mana_manager)
  self.mana_manager = mana_manager
end

function SpellPanel:set_on_play(callback) -- callback(spell, index)
  self.on_play_callback = callback
end

function SpellPanel:set_on_pass(callback) -- callback()
  self.on_pass_callback = callback
end

function SpellPanel:get_spell_count()
  return #self.spells
end

function SpellPanel:_get_spell_rect(index)
  local total_width = #self.spells * (self.spell_width + self.spell_spacing) - self.spell_spacing
  local start_x = (1280 - total_width) / 2
  local x = start_x + (index - 1) * (self.spell_width + self.spell_spacing)
  local y = 720 - self.spell_height - 20
  if index == self.hovered_index then
    y = y - 30
  end
  return x, y, self.spell_width, self.spell_height
end

function SpellPanel:update(dt)
  if not self.visible then return end
  local mx, my = love.mouse.getPosition()
  self.hovered_index = nil

  for i = #self.spells, 1, -1 do
    local cx, cy, cw, ch = self:_get_spell_rect(i)
    if mx >= cx and mx <= cx + cw and my >= cy and my <= cy + ch then
      self.hovered_index = i
      break
    end
  end
end

function SpellPanel:draw()
  if not self.visible then return end
  if #self.spells == 0 then return end

  for i, spell in ipairs(self.spells) do
    local cx, cy, cw, ch = self:_get_spell_rect(i)
    local playable = self.mana_manager and spell:can_play(self.mana_manager)
    local is_hovered = (i == self.hovered_index)

    if is_hovered then
      love.graphics.setColor(0.3, 0.3, 0.4, 1)
    elseif playable then
      love.graphics.setColor(0.2, 0.2, 0.3, 0.95)
    else
      love.graphics.setColor(0.15, 0.15, 0.15, 0.7)
    end
    love.graphics.rectangle("fill", cx, cy, cw, ch, 6, 6)

    if playable then
      love.graphics.setColor(0.6, 0.8, 1, 1)
    else
      love.graphics.setColor(0.4, 0.4, 0.4, 0.6)
    end
    love.graphics.rectangle("line", cx, cy, cw, ch, 6, 6)

    local cost = spell:get_cost()
    love.graphics.setColor(0, 0.4, 0.9, 1)
    love.graphics.circle("fill", cx + 16, cy + 16, 12)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.printf(tostring(cost), cx + 4, cy + 10, 24, "center")

    local text_alpha = playable and 1 or 0.5
    love.graphics.setColor(1, 1, 1, text_alpha)
    love.graphics.printf(spell:get_name(), cx + 4, cy + 35, cw - 8, "center")

    local susp = spell:get_suspicion_delta()
    if susp > 0 then
      love.graphics.setColor(1, 0.3, 0.3, text_alpha)
      love.graphics.printf(i18n.t("suspicion.increase", {value = susp}), cx + 4, cy + 55, cw - 8, "center")
    elseif susp < 0 then
      love.graphics.setColor(0.3, 1, 0.3, text_alpha)
      love.graphics.printf(i18n.t("suspicion.decrease", {value = susp}), cx + 4, cy + 55, cw - 8, "center")
    end

    if is_hovered then
      love.graphics.setColor(0.8, 0.8, 0.8, 1)
      love.graphics.printf(spell:get_description(), cx + 4, cy + 80, cw - 8, "center")
    end
  end

  love.graphics.setColor(1, 1, 1, 1)
end

function SpellPanel:mousepressed(mx, my, button)
  if not self.visible or button ~= 1 then return end

  for i = #self.spells, 1, -1 do
    local cx, cy, cw, ch = self:_get_spell_rect(i)
    if mx >= cx and mx <= cx + cw and my >= cy and my <= cy + ch then
      local spell = self.spells[i]
      if self.mana_manager and spell:can_play(self.mana_manager) then
        if self.on_play_callback then
          self.on_play_callback(spell, i)
        end
      end
      return
    end
  end
end

return SpellPanel
