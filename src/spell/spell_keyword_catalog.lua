local i18n = require("src.i18n.init")

---@class SpellKeywordEntry
---@field key string
---@field title_key string
---@field description_key string

---@class SpellKeywordCatalog
---@field entries table<string, SpellKeywordEntry>
local SpellKeywordCatalog = {}

SpellKeywordCatalog.entries = {
  char_single = {
    key = "char_single",
    title_key = "spell.keyword.char_single.title",
    description_key = "spell.keyword.char_single.description",
  },
  char_faction = {
    key = "char_faction",
    title_key = "spell.keyword.char_faction.title",
    description_key = "spell.keyword.char_faction.description",
  },
  char_all = {
    key = "char_all",
    title_key = "spell.keyword.char_all.title",
    description_key = "spell.keyword.char_all.description",
  },
  next_n = {
    key = "next_n",
    title_key = "spell.keyword.next_n.title",
    description_key = "spell.keyword.next_n.description",
  },
  next_all = {
    key = "next_all",
    title_key = "spell.keyword.next_all.title",
    description_key = "spell.keyword.next_all.description",
  },
  block = {
    key = "block",
    title_key = "spell.keyword.block.title",
    description_key = "spell.keyword.block.description",
  },
  speed = {
    key = "speed",
    title_key = "spell.keyword.speed.title",
    description_key = "spell.keyword.speed.description",
  },
  action_value = {
    key = "action_value",
    title_key = "spell.keyword.action_value.title",
    description_key = "spell.keyword.action_value.description",
  },
}

---@param keyword string
---@return SpellKeywordEntry|nil
function SpellKeywordCatalog.get(keyword)
  return SpellKeywordCatalog.entries[keyword]
end

---@param keyword string
---@return string
function SpellKeywordCatalog.get_title(keyword)
  local entry = SpellKeywordCatalog.get(keyword)
  if not entry then
    return keyword
  end
  return i18n.t(entry.title_key)
end

---@param keyword string
---@return string
function SpellKeywordCatalog.get_description(keyword)
  local entry = SpellKeywordCatalog.get(keyword)
  if not entry then
    return keyword
  end
  return i18n.t(entry.description_key)
end

return SpellKeywordCatalog
