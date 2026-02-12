local class = require('lib.middleclass')

---@class SpellBook
---@field spells Spell[]
---@field used_this_turn table
---@field reserved table
---@field new fun(self: SpellBook, spells: Spell[]): SpellBook
local SpellBook = class('SpellBook')

---@param spells Spell[]
function SpellBook:initialize(spells)
  self.spells = spells or {}
  self.used_this_turn = {}
  self.reserved = {}
end

--- Start a new planning phase: reset used and reserved
function SpellBook:start_planning()
  self.used_this_turn = {}
  self.reserved = {}
end

--- Check if a spell is available (not used this turn and not reserved)
---@param spell Spell
---@return boolean
function SpellBook:is_available(spell)
  return not self.used_this_turn[spell:get_id()]
      and not self.reserved[spell:get_id()]
end

--- Reserve a spell (for timeline placement)
---@param spell Spell
function SpellBook:reserve(spell)
  self.reserved[spell:get_id()] = spell
end

--- Unreserve a spell (remove from timeline)
---@param spell Spell
function SpellBook:unreserve(spell)
  self.reserved[spell:get_id()] = nil
end

--- Unreserve all spells, return released list for mana refund
---@return Spell[]
function SpellBook:unreserve_all()
  local released = {}
  for _, spell in pairs(self.reserved) do
    table.insert(released, spell)
  end
  self.reserved = {}
  return released
end

--- Confirm: move reserved spells to used_this_turn
function SpellBook:confirm()
  for id, _ in pairs(self.reserved) do
    self.used_this_turn[id] = true
  end
  self.reserved = {}
end

--- Mark a spell as used (immediate use, no reserve step)
---@param spell Spell
function SpellBook:mark_used(spell)
  self.used_this_turn[spell:get_id()] = true
end

--- Get all spells
---@return Spell[]
function SpellBook:get_all_spells()
  return self.spells
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
