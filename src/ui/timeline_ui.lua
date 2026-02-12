local class = require("lib.middleclass")
local UIElement = require("src.ui.ui_element")
local i18n = require("src.i18n.init")

---@class TimelineUI : UIElement
---@field timeline_manager TimelineManager|nil
---@field mode string "IDLE"|"INSERT_MODE"
---@field hovered_index number|nil
---@field selected_spell Spell|nil
---@field insert_index number|nil
---@field box_width number
---@field box_height number
---@field box_spacing number
---@field scroll_offset number
---@field max_visible number
---@field on_insert_callback function|nil
local TimelineUI = class("TimelineUI", UIElement)

function TimelineUI:initialize()
  UIElement.initialize(self, 0, 0, 1280, 120)
  self.timeline_manager = nil
  self.mode = "IDLE"
  self.hovered_index = nil
  self.selected_spell = nil
  self.insert_index = nil
  self.box_width = 50
  self.box_height = 60
  self.box_spacing = 6
  self.scroll_offset = 0
  self.max_visible = 18
  self.on_insert_callback = nil
end

---@param timeline_manager TimelineManager
function TimelineUI:set_timeline_manager(timeline_manager)
  self.timeline_manager = timeline_manager
end

---@param callback function(spell, index)
function TimelineUI:set_on_insert(callback)
  self.on_insert_callback = callback
end

--- Enter insert mode with a selected spell
---@param spell Spell
function TimelineUI:enter_insert_mode(spell)
  self.mode = "INSERT_MODE"
  self.selected_spell = spell
  self.insert_index = nil
end

--- Exit insert mode
function TimelineUI:exit_insert_mode()
  self.mode = "IDLE"
  self.selected_spell = nil
  self.insert_index = nil
end

function TimelineUI:_get_box_rect(index)
  local visible_index = index - self.scroll_offset
  local total_width = math.min(self.max_visible, self:_get_count()) * (self.box_width + self.box_spacing)
  local start_x = (1280 - total_width) / 2
  local x = start_x + (visible_index - 1) * (self.box_width + self.box_spacing)
  local y = 10
  return x, y, self.box_width, self.box_height
end

function TimelineUI:_get_count()
  if not self.timeline_manager then return 0 end
  return self.timeline_manager:get_count()
end

function TimelineUI:update(dt)
  if not self.visible or not self.timeline_manager then return end

  local mx, my = love.mouse.getPosition()
  self.hovered_index = nil

  local count = math.min(self.max_visible, self:_get_count())
  for i = 1, count do
    local actual_index = i + self.scroll_offset
    local bx, by, bw, bh = self:_get_box_rect(actual_index)
    if mx >= bx and mx <= bx + bw and my >= by and my <= by + bh then
      self.hovered_index = actual_index
      break
    end
  end

  -- In insert mode, calculate insertion point
  if self.mode == "INSERT_MODE" then
    self.insert_index = self:_calc_insert_index(mx)
  end
end

function TimelineUI:_calc_insert_index(mx)
  local count = self:_get_count()
  if count == 0 then return 1 end

  for i = 1, math.min(self.max_visible, count) do
    local actual_index = i + self.scroll_offset
    local bx, _, bw, _ = self:_get_box_rect(actual_index)
    if mx < bx + bw / 2 then
      return actual_index
    end
  end
  return count + 1
end

function TimelineUI:draw()
  if not self.visible or not self.timeline_manager then return end

  local timeline = self.timeline_manager:get_timeline()
  if #timeline == 0 then return end

  local count = math.min(self.max_visible, #timeline)

  -- Draw insert indicator
  if self.mode == "INSERT_MODE" and self.insert_index then
    local ix = self:_get_insert_x(self.insert_index)
    love.graphics.setColor(0.6, 0.3, 1, 0.8)
    love.graphics.rectangle("fill", ix - 2, 8, 4, self.box_height + 4, 2, 2)
  end

  for i = 1, count do
    local actual_index = i + self.scroll_offset
    local action = timeline[actual_index]
    if action then
      local bx, by, bw, bh = self:_get_box_rect(actual_index)
      local is_hovered = (actual_index == self.hovered_index)

      -- Background color by source type
      local source = action:get_source_type()
      if source == "hero" then
        love.graphics.setColor(0.2, 0.3, 0.6, 0.9)
      elseif source == "enemy" then
        love.graphics.setColor(0.6, 0.15, 0.15, 0.9)
      elseif source == "spell" then
        love.graphics.setColor(0.4, 0.2, 0.6, 0.9)
      end
      love.graphics.rectangle("fill", bx, by, bw, bh, 4, 4)

      -- Border
      if is_hovered then
        love.graphics.setColor(1, 1, 1, 1)
      else
        love.graphics.setColor(0.5, 0.5, 0.5, 0.6)
      end
      love.graphics.rectangle("line", bx, by, bw, bh, 4, 4)

      -- Action type icon (text)
      love.graphics.setColor(1, 1, 1, 0.9)
      local type_text = action:get_action_type()
      if type_text == "attack" then
        type_text = "ATK"
      elseif type_text == "defend" then
        type_text = "DEF"
      elseif type_text == "heal" then
        type_text = "HEL"
      end
      love.graphics.printf(type_text, bx + 2, by + 5, bw - 4, "center")

      -- Value
      local val = action:get_value()
      if val > 0 then
        love.graphics.setColor(1, 1, 0.8, 0.8)
        love.graphics.printf(tostring(val), bx + 2, by + 25, bw - 4, "center")
      end

      -- Index number
      love.graphics.setColor(0.7, 0.7, 0.7, 0.5)
      love.graphics.printf(tostring(actual_index), bx + 2, by + bh - 16, bw - 4, "center")
    end
  end

  -- Suspicion preview
  if self.timeline_manager:has_interventions() then
    local susp = self.timeline_manager:get_total_suspicion_preview()
    local susp_text = i18n.t("combat.suspicion_preview", {value = susp})
    if susp > 0 then
      love.graphics.setColor(1, 0.3, 0.3, 0.9)
    else
      love.graphics.setColor(0.3, 1, 0.3, 0.9)
    end
    love.graphics.printf(susp_text, 0, self.box_height + 18, 1280, "center")
  end

  -- Scroll indicator
  if #timeline > self.max_visible then
    love.graphics.setColor(0.7, 0.7, 0.7, 0.5)
    local info = string.format("%d-%d / %d", self.scroll_offset + 1,
      math.min(self.scroll_offset + self.max_visible, #timeline), #timeline)
    love.graphics.printf(info, 0, self.box_height + 18, 1280, "right")
  end

  -- Hovered action tooltip
  if self.hovered_index and timeline[self.hovered_index] then
    local action = timeline[self.hovered_index]
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.printf(action:get_description(), 0, self.box_height + 34, 1280, "center")
  end

  love.graphics.setColor(1, 1, 1, 1)
end

function TimelineUI:_get_insert_x(index)
  local visible_index = index - self.scroll_offset
  local total_width = math.min(self.max_visible, self:_get_count()) * (self.box_width + self.box_spacing)
  local start_x = (1280 - total_width) / 2
  return start_x + (visible_index - 1) * (self.box_width + self.box_spacing)
end

function TimelineUI:mousepressed(mx, my, button)
  if not self.visible or button ~= 1 then return false end

  if self.mode == "INSERT_MODE" and self.insert_index and self.selected_spell then
    if self.on_insert_callback then
      self.on_insert_callback(self.selected_spell, self.insert_index)
    end
    self:exit_insert_mode()
    return true
  end

  return false
end

function TimelineUI:wheelmoved(x, y)
  if not self.visible or not self.timeline_manager then return end
  local count = self:_get_count()
  if count <= self.max_visible then return end

  self.scroll_offset = self.scroll_offset - y
  self.scroll_offset = math.max(0, math.min(self.scroll_offset, count - self.max_visible))
end

return TimelineUI
