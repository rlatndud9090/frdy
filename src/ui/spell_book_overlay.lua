local class = require("lib.middleclass")
local UIElement = require("src.ui.ui_element")
local Gauge = require("src.ui.gauge")
local Button = require("src.ui.button")
local i18n = require("src.i18n.init")
local SpellKeywordCatalog = require("src.spell.spell_keyword_catalog")

---@class SpellBookOverlay : UIElement
---@field spell_book SpellBook|nil
---@field mana_manager ManaManager|nil
---@field suspicion_manager SuspicionManager|nil
---@field hero Entity|nil
---@field on_play_callback function|nil
---@field on_confirm_callback function|nil
---@field on_reset_callback function|nil
---@field active_tab string
---@field scroll_offset number
---@field hovered_spell_index number|nil
---@field suspicion_gauge Gauge
---@field mana_gauge Gauge
---@field confirm_button Button
---@field reset_button Button
local SpellBookOverlay = class("SpellBookOverlay", UIElement)

-- Constants
local TAB_NAMES = {"all", "insert"}
local TAB_LABEL_KEYS = {"spell.tab.all", "spell.tab.insert"}
local TAB_Y = 98
local TAB_HEIGHT = 32
local TAB_X = 15
local TAB_WIDTH = 250
local SPELL_LIST_Y = 136
local SPELL_LIST_HEIGHT = 526
local SPELL_ITEM_HEIGHT = 52
local SPELL_ITEM_SPACING = 4
local SPELL_ITEM_X = 15
local SPELL_ITEM_WIDTH = 250
local ITEMS_PER_PAGE = 8

function SpellBookOverlay:initialize()
  UIElement.initialize(self, 10, 10, 260, 690)

  self.spell_book = nil
  self.mana_manager = nil
  self.suspicion_manager = nil
  self.hero = nil
  self.on_play_callback = nil
  self.on_confirm_callback = nil
  self.on_reset_callback = nil
  self.active_tab = "all"
  self.scroll_offset = 0
  self.hovered_spell_index = nil

  -- Gauges (absolute coordinates)
  self.suspicion_gauge = Gauge:new(20, 15, 240, 22, "gauge.suspicion", {1, 0, 0})
  self.mana_gauge = Gauge:new(20, 42, 240, 22, "gauge.mana", {0, 0.5, 1})

  -- Buttons
  self.confirm_button = Button:new(15, 668, 120, 32, "ui.confirm")
  self.confirm_button:set_on_click(function()
    if self.on_confirm_callback then
      self.on_confirm_callback()
    end
  end)

  self.reset_button = Button:new(140, 668, 120, 32, "ui.reset")
  self.reset_button:set_on_click(function()
    if self.on_reset_callback then
      self.on_reset_callback()
    end
  end)
end

--- Setters
function SpellBookOverlay:set_spell_book(spell_book)
  self.spell_book = spell_book
end

function SpellBookOverlay:set_mana_manager(mana_manager)
  self.mana_manager = mana_manager
end

function SpellBookOverlay:set_suspicion_manager(suspicion_manager)
  self.suspicion_manager = suspicion_manager
end

function SpellBookOverlay:set_hero(hero)
  self.hero = hero
end

function SpellBookOverlay:set_on_play(callback)
  self.on_play_callback = callback
end

function SpellBookOverlay:set_on_confirm(callback)
  self.on_confirm_callback = callback
end

function SpellBookOverlay:set_on_reset(callback)
  self.on_reset_callback = callback
end

function SpellBookOverlay:set_active_tab(tab)
  self.active_tab = tab
  self.scroll_offset = 0
end

--- Internal methods
function SpellBookOverlay:_get_filtered_spells()
  if not self.spell_book then return {} end
  return self.spell_book:get_spells_by_type(self.active_tab)
end

function SpellBookOverlay:_get_spell_status(spell)
  if not self.spell_book then return "no_mana" end

  if self.spell_book:get_reserved_count(spell) > 0 then
    return "reserved"
  end
  if self.mana_manager and not spell:can_play(self.mana_manager) then
    return "no_mana"
  end
  return "playable"
end

function SpellBookOverlay:_is_playable(spell)
  return self.spell_book and self.mana_manager
    and spell:can_play(self.mana_manager)
end

--- Update
function SpellBookOverlay:update(dt)
  if not self.visible then return end

  -- Update gauge values
  if self.suspicion_manager then
    self.suspicion_gauge:set_value(self.suspicion_manager:get_level(), self.suspicion_manager:get_max())
  end
  if self.mana_manager then
    self.mana_gauge:set_value(self.mana_manager:get_current(), self.mana_manager:get_max())
  end
  -- Update hover state
  local mx, my = love.mouse.getPosition()
  self.hovered_spell_index = nil

  local filtered = self:_get_filtered_spells()
  for i = 1, #filtered do
    local item_y = SPELL_LIST_Y + (i - 1 - self.scroll_offset) * (SPELL_ITEM_HEIGHT + SPELL_ITEM_SPACING)
    if mx >= SPELL_ITEM_X and mx <= SPELL_ITEM_X + SPELL_ITEM_WIDTH
      and my >= item_y and my <= item_y + SPELL_ITEM_HEIGHT
      and my >= SPELL_LIST_Y and my <= SPELL_LIST_Y + SPELL_LIST_HEIGHT then
      self.hovered_spell_index = i
      break
    end
  end

  -- Update buttons
  self.confirm_button:update(dt)
  self.reset_button:update(dt)
end

--- Draw
function SpellBookOverlay:draw()
  if not self.visible then return end

  -- Panel background
  love.graphics.setColor(0.1, 0.1, 0.15, 0.95)
  love.graphics.rectangle("fill", self.x, self.y, self.width, self.height, 8, 8)

  -- Panel border
  love.graphics.setColor(0.3, 0.3, 0.4, 1)
  love.graphics.rectangle("line", self.x, self.y, self.width, self.height, 8, 8)

  self:_draw_status_section()
  self:_draw_tab_bar()
  self:_draw_spell_list()
  self:_draw_action_bar()
  self:_draw_hovered_spell_details()

  love.graphics.setColor(1, 1, 1, 1)
end

function SpellBookOverlay:_draw_status_section()
  self.suspicion_gauge:draw()
  self.mana_gauge:draw()

  -- Phase text
  love.graphics.setColor(0.7, 0.7, 0.7, 0.8)
  love.graphics.print("Planning", 20, 72)
end

function SpellBookOverlay:_draw_tab_bar()
  local tab_count = #TAB_NAMES
  local tab_w = math.floor(TAB_WIDTH / tab_count)

  for i, tab_name in ipairs(TAB_NAMES) do
    local tx = TAB_X + (i - 1) * tab_w
    local is_active = (self.active_tab == tab_name)

    -- Background
    if is_active then
      love.graphics.setColor(0.3, 0.3, 0.5, 1)
    else
      love.graphics.setColor(0.15, 0.15, 0.2, 0.8)
    end
    love.graphics.rectangle("fill", tx, TAB_Y, tab_w, TAB_HEIGHT, 4, 4)

    -- Active indicator line
    if is_active then
      love.graphics.setColor(0.6, 0.8, 1, 1)
      love.graphics.line(tx, TAB_Y + TAB_HEIGHT - 1, tx + tab_w, TAB_Y + TAB_HEIGHT - 1)
    end

    -- Tab label
    love.graphics.setColor(1, 1, 1, is_active and 1 or 0.6)
    local tab_label = i18n.t(TAB_LABEL_KEYS[i])
    local font_h = love.graphics.getFont():getHeight()
    local text_y = TAB_Y + (TAB_HEIGHT - font_h) * 0.5 - 1
    love.graphics.printf(tab_label, tx, text_y, tab_w, "center")
  end
end

function SpellBookOverlay:_draw_spell_list()
  local spells = self:_get_filtered_spells()

  if #spells == 0 then
    love.graphics.setColor(0.5, 0.5, 0.5, 0.6)
    love.graphics.printf("No spells", SPELL_ITEM_X, SPELL_LIST_Y + 20, SPELL_ITEM_WIDTH, "center")
    return
  end

  -- Scissor clip for scrolling
  love.graphics.setScissor(SPELL_ITEM_X, SPELL_LIST_Y, SPELL_ITEM_WIDTH, SPELL_LIST_HEIGHT)

  for i, spell in ipairs(spells) do
    local item_y = SPELL_LIST_Y + (i - 1 - self.scroll_offset) * (SPELL_ITEM_HEIGHT + SPELL_ITEM_SPACING)
    self:_draw_spell_item(spell, i, item_y)
  end

  -- Clear scissor
  love.graphics.setScissor()

  -- Scroll indicator bar
  if #spells > ITEMS_PER_PAGE then
    love.graphics.setColor(0.4, 0.4, 0.5, 0.8)
    local bar_h = (ITEMS_PER_PAGE / #spells) * SPELL_LIST_HEIGHT
    local max_scroll = #spells - ITEMS_PER_PAGE
    local bar_y = SPELL_LIST_Y
    if max_scroll > 0 then
      bar_y = SPELL_LIST_Y + (self.scroll_offset / max_scroll) * (SPELL_LIST_HEIGHT - bar_h)
    end
    love.graphics.rectangle("fill", SPELL_ITEM_X + SPELL_ITEM_WIDTH + 2, bar_y, 4, bar_h, 2, 2)
  end
end

function SpellBookOverlay:_draw_spell_item(spell, index, y)
  local status = self:_get_spell_status(spell)
  local is_hovered = (index == self.hovered_spell_index)
  local can_play = self:_is_playable(spell)

  -- Background color by status
  if is_hovered and can_play then
    love.graphics.setColor(0.3, 0.3, 0.5, 1)
  elseif status == "reserved" then
    love.graphics.setColor(0.22, 0.16, 0.33, 0.95)
  elseif can_play then
    love.graphics.setColor(0.2, 0.2, 0.3, 0.9)
  elseif status == "no_mana" then
    love.graphics.setColor(0.15, 0.15, 0.15, 0.7)
  else
    love.graphics.setColor(0.2, 0.2, 0.3, 0.9)
  end
  love.graphics.rectangle("fill", SPELL_ITEM_X, y, SPELL_ITEM_WIDTH, SPELL_ITEM_HEIGHT, 4, 4)

  -- Border by status
  if is_hovered and can_play then
    love.graphics.setColor(0.8, 0.9, 1, 1)
  elseif status == "reserved" then
    love.graphics.setColor(0.7, 0.45, 1, 1)
  elseif can_play then
    love.graphics.setColor(0.6, 0.8, 1, 1)
  elseif status == "no_mana" then
    love.graphics.setColor(0.4, 0.4, 0.4, 0.6)
  else
    love.graphics.setColor(0.6, 0.8, 1, 1)
  end
  love.graphics.rectangle("line", SPELL_ITEM_X, y, SPELL_ITEM_WIDTH, SPELL_ITEM_HEIGHT, 4, 4)

  -- Mana cost circle
  love.graphics.setColor(0, 0.4, 0.9, 1)
  love.graphics.circle("fill", SPELL_ITEM_X + 14, y + 16, 10)
  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.printf(tostring(spell:get_cost()), SPELL_ITEM_X + 4, y + 10, 20, "center")

  -- Text alpha based on status
  local text_alpha = 1
  if status == "reserved" then text_alpha = 0.8
  elseif status == "no_mana" then text_alpha = 0.5
  end

  -- Spell name
  love.graphics.setColor(1, 1, 1, text_alpha)
  love.graphics.print(spell:get_name(), SPELL_ITEM_X + 30, y + 4)

  -- Status label (right-aligned)
  if status == "reserved" then
    local count = self.spell_book and self.spell_book:get_reserved_count(spell) or 0
    love.graphics.setColor(0.8, 0.4, 1, text_alpha * 0.8)
    love.graphics.printf(i18n.t("spell.reserved") .. " x" .. tostring(count), SPELL_ITEM_X, y + 4, SPELL_ITEM_WIDTH - 8, "right")
  elseif status == "no_mana" then
    love.graphics.setColor(0.5, 0.5, 0.5, text_alpha * 0.8)
    love.graphics.printf("MANA", SPELL_ITEM_X, y + 4, SPELL_ITEM_WIDTH - 8, "right")
  end

  -- Row 2: mana cost + suspicion delta
  love.graphics.setColor(0, 0.5, 1, text_alpha * 0.8)
  love.graphics.print(spell:get_cost() .. " mana", SPELL_ITEM_X + 30, y + 25)

  local susp = spell.get_suspicion_abs and spell:get_suspicion_abs() or math.abs(spell:get_suspicion_delta())
  local target_mode = spell.get_target_mode and spell:get_target_mode() or "char_single"
  if susp ~= 0 and (target_mode == "char_single" or target_mode == "char_faction") then
    love.graphics.setColor(1, 0.85, 0.35, text_alpha * 0.85)
    love.graphics.print(i18n.t("spell.suspicion_targeted", {value = math.abs(susp)}), SPELL_ITEM_X + 120, y + 25)
  elseif susp ~= 0 and (target_mode == "action_next_n" or target_mode == "action_next_all") then
    love.graphics.setColor(1, 0.85, 0.35, text_alpha * 0.85)
    love.graphics.print(i18n.t("spell.suspicion_per_action", {value = math.abs(susp)}), SPELL_ITEM_X + 120, y + 25)
  end
end

function SpellBookOverlay:_draw_action_bar()
  self.confirm_button:draw()
  self.reset_button:draw()
end

---@return Spell|nil
function SpellBookOverlay:_get_hovered_spell()
  if not self.hovered_spell_index then
    return nil
  end

  local filtered = self:_get_filtered_spells()
  return filtered[self.hovered_spell_index]
end

function SpellBookOverlay:_draw_hovered_spell_details()
  local spell = self:_get_hovered_spell()
  if not spell then
    return
  end

  local panel_x = 280
  local panel_y = 510
  local panel_w = 520
  local panel_h = 210

  love.graphics.setColor(0.08, 0.08, 0.12, 0.92)
  love.graphics.rectangle("fill", panel_x, panel_y, panel_w, panel_h, 8, 8)
  love.graphics.setColor(0.45, 0.45, 0.58, 0.95)
  love.graphics.rectangle("line", panel_x, panel_y, panel_w, panel_h, 8, 8)

  love.graphics.setColor(1, 1, 1, 0.95)
  love.graphics.printf(spell:get_name(), panel_x + 12, panel_y + 10, panel_w - 24, "left")

  love.graphics.setColor(0.85, 0.9, 1, 0.92)
  love.graphics.printf(spell:get_description(), panel_x + 12, panel_y + 32, panel_w - 24, "left")

  local cursor_y = panel_y + 78
  local status_entries = spell.get_status_entries and spell:get_status_entries() or {}
  if #status_entries > 0 then
    love.graphics.setColor(0.95, 0.85, 0.4, 0.95)
    love.graphics.printf(i18n.t("spell.statuses"), panel_x + 12, cursor_y, panel_w - 24, "left")
    cursor_y = cursor_y + 22

    for _, status in ipairs(status_entries) do
      if cursor_y > panel_y + panel_h - 18 then
        break
      end

      love.graphics.setColor(0.9, 0.92, 1, 0.92)
      love.graphics.printf("[" .. status.title .. "] " .. status.description, panel_x + 12, cursor_y, panel_w - 24, "left")
      cursor_y = cursor_y + 18
    end
  end

  local keywords = spell.get_keywords and spell:get_keywords() or {}
  if #keywords == 0 then
    return
  end

  love.graphics.setColor(0.95, 0.85, 0.4, 0.95)
  love.graphics.printf(i18n.t("spell.keywords"), panel_x + 12, cursor_y, panel_w - 24, "left")
  cursor_y = cursor_y + 22

  for _, keyword in ipairs(keywords) do
    if cursor_y > panel_y + panel_h - 18 then
      break
    end

    if SpellKeywordCatalog.get(keyword) then
      local title = SpellKeywordCatalog.get_title(keyword)
      local description = SpellKeywordCatalog.get_description(keyword)
      love.graphics.setColor(0.9, 0.92, 1, 0.92)
      love.graphics.printf("[" .. title .. "] " .. description, panel_x + 12, cursor_y, panel_w - 24, "left")
      cursor_y = cursor_y + 18
    end
  end
end

--- Handle only confirm/reset buttons.
---@param mx number
---@param my number
---@param button number
---@return boolean
function SpellBookOverlay:mousepressed_action_buttons(mx, my, button)
  if not self.visible or button ~= 1 then
    return false
  end

  if self.confirm_button:hit_test(mx, my) then
    self.confirm_button:mousepressed(mx, my, button)
    return true
  end
  if self.reset_button:hit_test(mx, my) then
    self.reset_button:mousepressed(mx, my, button)
    return true
  end
  return false
end

--- Input handling
function SpellBookOverlay:mousepressed(mx, my, button)
  if not self.visible or button ~= 1 then return false end
  if not self:hit_test(mx, my) then return false end

  -- Tab bar click
  if my >= TAB_Y and my <= TAB_Y + TAB_HEIGHT and mx >= TAB_X and mx <= TAB_X + TAB_WIDTH then
    local tab_w = TAB_WIDTH / #TAB_NAMES
    local tab_index = math.floor((mx - TAB_X) / tab_w) + 1
    tab_index = math.max(1, math.min(#TAB_NAMES, tab_index))
    self:set_active_tab(TAB_NAMES[tab_index])
    return true
  end

  -- Spell list click
  if my >= SPELL_LIST_Y and my <= SPELL_LIST_Y + SPELL_LIST_HEIGHT then
    local relative_y = my - SPELL_LIST_Y
    local item_index = math.floor(relative_y / (SPELL_ITEM_HEIGHT + SPELL_ITEM_SPACING)) + 1 + self.scroll_offset
    local filtered = self:_get_filtered_spells()
    local spell = filtered[item_index]
    if spell and self:_is_playable(spell) and self.on_play_callback then
      self.on_play_callback(spell)
    end
    return true
  end

  -- Button clicks
  self.confirm_button:mousepressed(mx, my, button)
  self.reset_button:mousepressed(mx, my, button)

  return true
end

function SpellBookOverlay:wheelmoved(x, y)
  if not self.visible then return end
  local filtered = self:_get_filtered_spells()
  local max_scroll = math.max(0, #filtered - ITEMS_PER_PAGE)
  self.scroll_offset = math.max(0, math.min(self.scroll_offset - y, max_scroll))
end

return SpellBookOverlay
