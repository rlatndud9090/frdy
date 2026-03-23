---@class SaveSanitizer
local SaveSanitizer = {}

local MAX_DEPTH = 16

---@param value number|nil
---@param default_value number
---@param min_value? number
---@param max_value? number
---@return number
function SaveSanitizer.number(value, default_value, min_value, max_value)
  local numeric = tonumber(value)
  if numeric == nil or numeric ~= numeric or numeric == math.huge or numeric == -math.huge then
    numeric = default_value
  end

  if min_value ~= nil and numeric < min_value then
    numeric = min_value
  end
  if max_value ~= nil and numeric > max_value then
    numeric = max_value
  end

  return numeric
end

---@param value number|nil
---@param default_value number
---@param min_value? number
---@param max_value? number
---@return number
function SaveSanitizer.integer(value, default_value, min_value, max_value)
  return math.floor(SaveSanitizer.number(value, default_value, min_value, max_value))
end

---@param value any
---@param default_value string
---@return string
function SaveSanitizer.string(value, default_value)
  if type(value) == "string" then
    return value
  end
  return default_value
end

---@param value any
---@param allowed table<string, boolean>
---@param default_value string
---@return string
function SaveSanitizer.enum(value, allowed, default_value)
  if type(value) == "string" and allowed[value] then
    return value
  end
  return default_value
end

---@param value any
---@param default_value boolean
---@return boolean
function SaveSanitizer.boolean(value, default_value)
  if type(value) == "boolean" then
    return value
  end
  return default_value
end

---@param list any
---@param item_sanitizer fun(value: any, index: integer): any
---@return table
function SaveSanitizer.array(list, item_sanitizer)
  local result = {}
  if type(list) ~= "table" then
    return result
  end

  for index, value in ipairs(list) do
    result[index] = item_sanitizer(value, index)
  end

  return result
end

---@param map any
---@param value_sanitizer fun(value: any, key: string): any
---@return table<string, any>
function SaveSanitizer.string_key_map(map, value_sanitizer)
  local result = {}
  if type(map) ~= "table" then
    return result
  end

  local keys = {}
  for key, _ in pairs(map) do
    if type(key) == "string" then
      keys[#keys + 1] = key
    end
  end
  table.sort(keys)

  for _, key in ipairs(keys) do
    result[key] = value_sanitizer(map[key], key)
  end

  return result
end

---@param value any
---@param depth? number
---@return any
function SaveSanitizer.plain_data(value, depth)
  local current_depth = depth or 0
  if current_depth > MAX_DEPTH then
    return nil
  end

  local value_type = type(value)
  if value_type == "nil" or value_type == "boolean" or value_type == "string" then
    return value
  end

  if value_type == "number" then
    if value ~= value or value == math.huge or value == -math.huge then
      return nil
    end
    return value
  end

  if value_type ~= "table" then
    return nil
  end

  local result = {}
  local array_length = #value
  local numeric_count = 0

  for key, item in pairs(value) do
    if type(key) == "number" then
      if key < 1 or key > array_length or math.floor(key) ~= key then
        return nil
      end
      numeric_count = numeric_count + 1
    elseif type(key) ~= "string" then
      return nil
    end

    local sanitized = SaveSanitizer.plain_data(item, current_depth + 1)
    if sanitized ~= nil then
      result[key] = sanitized
    end
  end

  if numeric_count > 0 and numeric_count ~= array_length then
    return nil
  end

  return result
end

return SaveSanitizer
