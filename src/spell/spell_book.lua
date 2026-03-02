local class = require('lib.middleclass')

---@class SpellBook
---@field spells Spell[]
---@field used_this_turn table<string, number>
---@field reserved table<string, number>
---@field reserved_stack Spell[]
---@field new fun(self: SpellBook, spells: Spell[]): SpellBook
local SpellBook = class('SpellBook')

---@param spells Spell[]
function SpellBook:initialize(spells)
  self.spells = spells or {}
  self.used_this_turn = {}
  self.reserved = {}
  self.reserved_stack = {}
end

--- Start a new planning phase: reset used and reserved
function SpellBook:start_planning()
  self.used_this_turn = {}
  self.reserved = {}
  self.reserved_stack = {}
end

--- Check if a spell can be selected from book.
--- 동일 마법을 한 턴에 여러 번 사용 가능하므로 사용/예약으로 막지 않는다.
---@param spell Spell
---@return boolean
function SpellBook:is_available(spell)
  return spell ~= nil
end

--- Reserve a spell (for timeline placement)
---@param spell Spell
function SpellBook:reserve(spell)
  local id = spell:get_id()
  self.reserved[id] = (self.reserved[id] or 0) + 1
  self.reserved_stack[#self.reserved_stack + 1] = spell
end

--- Unreserve a spell (remove from timeline)
---@param spell Spell
function SpellBook:unreserve(spell)
  local id = spell:get_id()
  local count = self.reserved[id] or 0
  if count <= 0 then
    return
  end

  if count == 1 then
    self.reserved[id] = nil
  else
    self.reserved[id] = count - 1
  end

  for i = #self.reserved_stack, 1, -1 do
    if self.reserved_stack[i]:get_id() == id then
      table.remove(self.reserved_stack, i)
      break
    end
  end
end

--- Unreserve all spells, return released list for mana refund
---@return Spell[]
function SpellBook:unreserve_all()
  local released = {}
  for _, spell in ipairs(self.reserved_stack) do
    released[#released + 1] = spell
  end
  self.reserved = {}
  self.reserved_stack = {}
  return released
end

--- Confirm: move reserved spells to used_this_turn
function SpellBook:confirm()
  for id, count in pairs(self.reserved) do
    self.used_this_turn[id] = (self.used_this_turn[id] or 0) + count
  end
  self.reserved = {}
  self.reserved_stack = {}
end

--- Mark a spell as used (immediate use, no reserve step)
---@param spell Spell
function SpellBook:mark_used(spell)
  local id = spell:get_id()
  self.used_this_turn[id] = (self.used_this_turn[id] or 0) + 1
end

---@param spell Spell
---@return number
function SpellBook:get_reserved_count(spell)
  return self.reserved[spell:get_id()] or 0
end

---@param spell Spell
---@return number
function SpellBook:get_used_count(spell)
  return self.used_this_turn[spell:get_id()] or 0
end

--- Get all spells
---@return Spell[]
function SpellBook:get_all_spells()
  return self.spells
end

---@param spell_id string
---@return Spell|nil
function SpellBook:get_spell_by_id(spell_id)
  for _, spell in ipairs(self.spells) do
    if spell:get_id() == spell_id then
      return spell
    end
  end
  return nil
end

---@param spell_id string
---@return boolean
function SpellBook:has_spell(spell_id)
  return self:get_spell_by_id(spell_id) ~= nil
end

--- Filter spells by timeline type
---@param type_filter string "all"|"insert"|"manipulate"|"global"
---@return Spell[]
function SpellBook:get_spells_by_type(type_filter)
  if type_filter == "all" then
    return self.spells
  end
  local result = {}
  for _, spell in ipairs(self.spells) do
    local ttype = spell:get_timeline_type()
    if type_filter == "insert" and ttype == "insert" then
      table.insert(result, spell)
    elseif type_filter == "manipulate" and ttype:sub(1,10) == "manipulate" then
      table.insert(result, spell)
    elseif type_filter == "global" and ttype == "global" then
      table.insert(result, spell)
    end
  end
  return result
end

--- Get available (playable) spells
---@return Spell[]
function SpellBook:get_available_spells()
  local available = {}
  for _, spell in ipairs(self.spells) do
    if self:is_available(spell) then
      table.insert(available, spell)
    end
  end
  return available
end

--- Add a spell to the book
---@param spell Spell
function SpellBook:add_spell(spell)
  table.insert(self.spells, spell)
end

--- Remove a spell from the book
---@param spell Spell
---@return boolean
function SpellBook:remove_spell(spell)
  for i = #self.spells, 1, -1 do
    if self.spells[i]:get_id() == spell:get_id() then
      table.remove(self.spells, i)
      return true
    end
  end
  return false
end

return SpellBook
