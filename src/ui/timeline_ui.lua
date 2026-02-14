local class = require("lib.middleclass")
local UIElement = require("src.ui.ui_element")
local i18n = require("src.i18n.init")

---@class TimelineUI : UIElement
---@field timeline_manager TimelineManager|nil
---@field mode string "IDLE"|"INSERT_MODE"|"MANIPULATE_SELECT_TARGET"|"MANIPULATE_SELECT_DEST"
---@field hovered_index number|nil
---@field selected_spell Spell|nil
---@field insert_index number|nil
---@field manipulate_target_index number|nil
---@field box_width number
---@field box_height number
---@field box_spacing number
---@field scroll_offset number
---@field max_visible number
---@field on_insert_callback function|nil
---@field on_manipulate_callback function|nil
---@field on_global_callback function|nil
---@field tooltip_line_height number
local TimelineUI = class("TimelineUI", UIElement)

function TimelineUI:initialize()
  UIElement.initialize(self, 0, 0, 1280, 120)
  self.timeline_manager = nil
  self.mode = "IDLE"
  self.hovered_index = nil
  self.selected_spell = nil
  self.insert_index = nil
  self.manipulate_target_index = nil
  self.box_width = 50
  self.box_height = 60
  self.box_spacing = 6
  self.scroll_offset = 0
  self.max_visible = 15
  self.on_insert_callback = nil
  self.on_manipulate_callback = nil
  self.on_global_callback = nil
  self.tooltip_line_height = 18
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
  self.manipulate_target_index = nil
end

---@param callback function(spell, target_index, dest_index)
function TimelineUI:set_on_manipulate(callback)
  self.on_manipulate_callback = callback
end

---@param callback function(spell)
function TimelineUI:set_on_global(callback)
  self.on_global_callback = callback
end

--- Enter manipulate mode: select a target action on the timeline
---@param spell Spell
function TimelineUI:enter_manipulate_mode(spell)
  self.mode = "MANIPULATE_SELECT_TARGET"
  self.selected_spell = spell
  self.manipulate_target_index = nil
end

--- Enter global mode: apply immediately, no target needed
---@param spell Spell
function TimelineUI:enter_global_mode(spell)
  if self.on_global_callback then
    self.on_global_callback(spell)
  end
end

function TimelineUI:_get_box_rect(index)
  local visible_index = index - self.scroll_offset
  local area_x = 280
  local area_width = 1000  -- 1280 - 280
  local total_width = math.min(self.max_visible, self:_get_count()) * (self.box_width + self.box_spacing)
  local start_x = area_x + (area_width - total_width) / 2
  local x = start_x + (visible_index - 1) * (self.box_width + self.box_spacing)
  local y = 140
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
    love.graphics.rectangle("fill", ix - 2, 138, 4, self.box_height + 4, 2, 2)
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

      -- Border: highlight for manipulation modes
      local is_manip_target = (self.mode == "MANIPULATE_SELECT_DEST" and actual_index == self.manipulate_target_index)
      local is_manip_hover = ((self.mode == "MANIPULATE_SELECT_TARGET" or self.mode == "MANIPULATE_SELECT_DEST") and is_hovered)
      if is_manip_target then
        love.graphics.setColor(1, 0.8, 0, 1)
        love.graphics.setLineWidth(2)
      elseif is_manip_hover then
        love.graphics.setColor(1, 0.5, 0, 1)
        love.graphics.setLineWidth(2)
      elseif is_hovered then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setLineWidth(1)
      else
        love.graphics.setColor(0.5, 0.5, 0.5, 0.6)
        love.graphics.setLineWidth(1)
      end
      love.graphics.rectangle("line", bx, by, bw, bh, 4, 4)
      love.graphics.setLineWidth(1)

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
    love.graphics.printf(susp_text, 280, 208, 1000, "center")
  end

  -- Scroll indicator
  if #timeline > self.max_visible then
    love.graphics.setColor(0.7, 0.7, 0.7, 0.5)
    local info = string.format("%d-%d / %d", self.scroll_offset + 1,
      math.min(self.scroll_offset + self.max_visible, #timeline), #timeline)
    love.graphics.printf(info, 280, 208, 1000, "right")
  end

  -- Hovered action tooltip
  if self.hovered_index and timeline[self.hovered_index] then
    local action = timeline[self.hovered_index]
    love.graphics.setColor(1, 1, 1, 0.9)
    love.graphics.printf(action:get_description(), 280, 224, 1000, "center")
    self:_draw_hover_snapshot(action)
  end

  -- Mode hint text
  if self.mode == "MANIPULATE_SELECT_TARGET" then
    love.graphics.setColor(1, 0.8, 0, 0.9)
    love.graphics.printf(i18n.t("combat.select_target"), 280, 120, 1000, "center")
  elseif self.mode == "MANIPULATE_SELECT_DEST" then
    love.graphics.setColor(1, 0.5, 0, 0.9)
    love.graphics.printf(i18n.t("combat.select_destination"), 280, 120, 1000, "center")
  end

  love.graphics.setColor(1, 1, 1, 1)
end

---@param action PredictedAction
function TimelineUI:_draw_hover_snapshot(action)
  local snapshot = action:get_state_snapshot()
  if not snapshot then return end

  local start_y = 244
  love.graphics.setColor(0.95, 0.95, 1, 0.95)
  local hero_text = i18n.t("combat.timeline_hover_hero_hp", {
    current = snapshot.hero_hp,
    max = snapshot.hero_max_hp,
  })
  love.graphics.printf(hero_text, 280, start_y, 1000, "center")

  local enemies = snapshot.enemies or {}
  if #enemies == 0 then
    local none_text = i18n.t("combat.timeline_hover_no_enemies")
    love.graphics.setColor(0.85, 0.85, 0.9, 0.9)
    love.graphics.printf(none_text, 280, start_y + self.tooltip_line_height, 1000, "center")
    return
  end

  local enemy_lines = {}
  for _, enemy_state in ipairs(enemies) do
    if enemy_state.alive then
      table.insert(enemy_lines, i18n.t("combat.timeline_hover_enemy_hp", {
        name = enemy_state.name,
        current = enemy_state.hp,
        max = enemy_state.max_hp,
      }))
    end
  end

  if #enemy_lines == 0 then
    local none_text = i18n.t("combat.timeline_hover_no_enemies")
    love.graphics.setColor(0.85, 0.85, 0.9, 0.9)
    love.graphics.printf(none_text, 280, start_y + self.tooltip_line_height, 1000, "center")
    return
  end

  love.graphics.setColor(0.92, 0.86, 0.86, 0.95)
  for i, line in ipairs(enemy_lines) do
    love.graphics.printf(line, 280, start_y + (i * self.tooltip_line_height), 1000, "center")
  end
end

function TimelineUI:_get_insert_x(index)
  local visible_index = index - self.scroll_offset
  local area_x = 280
  local area_width = 1000
  local total_width = math.min(self.max_visible, self:_get_count()) * (self.box_width + self.box_spacing)
  local start_x = area_x + (area_width - total_width) / 2
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

  if self.mode == "MANIPULATE_SELECT_TARGET" and self.hovered_index then
    local timeline_type = self.selected_spell:get_timeline_type()
    if timeline_type == "manipulate_swap" then
      -- Swap needs a second target
      self.manipulate_target_index = self.hovered_index
      self.mode = "MANIPULATE_SELECT_DEST"
    else
      -- remove, delay, modify: single target
      if self.on_manipulate_callback then
        self.on_manipulate_callback(self.selected_spell, self.hovered_index, nil)
      end
      self:exit_insert_mode()
    end
    return true
  end

  if self.mode == "MANIPULATE_SELECT_DEST" and self.hovered_index then
    if self.on_manipulate_callback then
      self.on_manipulate_callback(self.selected_spell, self.manipulate_target_index, self.hovered_index)
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
