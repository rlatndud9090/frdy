---@class JsonCodec
local JsonCodec = {}

---@param value any
---@return boolean
local function is_array(value)
  if type(value) ~= "table" then
    return false
  end

  local length = #value
  local numeric_keys = 0
  for key in pairs(value) do
    if type(key) == "number" then
      if key < 1 or key > length or math.floor(key) ~= key then
        return false
      end
      numeric_keys = numeric_keys + 1
    elseif type(key) ~= "string" then
      return false
    else
      return false
    end
  end

  return numeric_keys == length
end

---@param value string
---@return string
local function escape_string(value)
  local substitutions = {
    ["\\"] = "\\\\",
    ["\""] = "\\\"",
    ["\b"] = "\\b",
    ["\f"] = "\\f",
    ["\n"] = "\\n",
    ["\r"] = "\\r",
    ["\t"] = "\\t",
  }

  return value:gsub("[%z\1-\31\\\"]", function(char)
    return substitutions[char] or string.format("\\u%04x", string.byte(char))
  end)
end

---@param value any
---@return string|nil
---@return string|nil
local function encode_value(value)
  local value_type = type(value)
  if value_type == "nil" then
    return "null", nil
  end
  if value_type == "boolean" then
    return value and "true" or "false", nil
  end
  if value_type == "number" then
    if value ~= value or value == math.huge or value == -math.huge then
      return nil, "JSON does not support NaN or Infinity."
    end
    return tostring(value), nil
  end
  if value_type == "string" then
    return "\"" .. escape_string(value) .. "\"", nil
  end
  if value_type ~= "table" then
    return nil, "JSON does not support value type: " .. value_type
  end

  if is_array(value) then
    local parts = {"["}
    for index = 1, #value do
      local encoded, err = encode_value(value[index])
      if not encoded then
        return nil, err
      end
      if index > 1 then
        parts[#parts + 1] = ","
      end
      parts[#parts + 1] = encoded
    end
    parts[#parts + 1] = "]"
    return table.concat(parts), nil
  end

  local keys = {}
  for key in pairs(value) do
    if type(key) ~= "string" then
      return nil, "JSON object keys must be strings."
    end
    keys[#keys + 1] = key
  end
  table.sort(keys)

  local parts = {"{"}
  for index, key in ipairs(keys) do
    local encoded, err = encode_value(value[key])
    if not encoded then
      return nil, err
    end
    if index > 1 then
      parts[#parts + 1] = ","
    end
    parts[#parts + 1] = "\"" .. escape_string(key) .. "\":" .. encoded
  end
  parts[#parts + 1] = "}"
  return table.concat(parts), nil
end

---@param text string
---@param index integer
---@return integer
local function skip_whitespace(text, index)
  local cursor = index
  while cursor <= #text do
    local char = text:sub(cursor, cursor)
    if char ~= " " and char ~= "\n" and char ~= "\r" and char ~= "\t" then
      break
    end
    cursor = cursor + 1
  end
  return cursor
end

---@param text string
---@param start_index integer
---@return number|nil
---@return integer|nil
---@return string|nil
local function decode_unicode_escape(text, start_index)
  local hex = text:sub(start_index, start_index + 3)
  if #hex ~= 4 or not hex:match("^[0-9a-fA-F]+$") then
    return nil, nil, "Invalid unicode escape in JSON string."
  end

  local codepoint = tonumber(hex, 16)
  if not codepoint then
    return nil, nil, "Invalid unicode escape in JSON string."
  end

  if codepoint >= 0xD800 and codepoint <= 0xDBFF then
    local next_prefix = text:sub(start_index + 4, start_index + 5)
    local low_hex = text:sub(start_index + 6, start_index + 9)
    if next_prefix ~= "\\u" or #low_hex ~= 4 or not low_hex:match("^[0-9a-fA-F]+$") then
      return nil, nil, "Invalid unicode surrogate pair in JSON string."
    end

    local low_surrogate = tonumber(low_hex, 16)
    if not low_surrogate or low_surrogate < 0xDC00 or low_surrogate > 0xDFFF then
      return nil, nil, "Invalid unicode surrogate pair in JSON string."
    end

    codepoint = 0x10000 + ((codepoint - 0xD800) * 0x400) + (low_surrogate - 0xDC00)
    return codepoint, start_index + 10, nil
  end

  if codepoint >= 0xDC00 and codepoint <= 0xDFFF then
    return nil, nil, "Invalid unicode surrogate pair in JSON string."
  end

  return codepoint, start_index + 4, nil
end

---@param text string
---@param index integer
---@return string|nil
---@return integer|nil
---@return string|nil
local function parse_string(text, index)
  local cursor = index + 1
  local parts = {}

  while cursor <= #text do
    local char = text:sub(cursor, cursor)
    if char == "\"" then
      return table.concat(parts), cursor + 1, nil
    end

    if char == "\\" then
      local next_char = text:sub(cursor + 1, cursor + 1)
      if next_char == "\"" or next_char == "\\" or next_char == "/" then
        parts[#parts + 1] = next_char
        cursor = cursor + 2
      elseif next_char == "b" then
        parts[#parts + 1] = "\b"
        cursor = cursor + 2
      elseif next_char == "f" then
        parts[#parts + 1] = "\f"
        cursor = cursor + 2
      elseif next_char == "n" then
        parts[#parts + 1] = "\n"
        cursor = cursor + 2
      elseif next_char == "r" then
        parts[#parts + 1] = "\r"
        cursor = cursor + 2
      elseif next_char == "t" then
        parts[#parts + 1] = "\t"
        cursor = cursor + 2
      elseif next_char == "u" then
        local codepoint, next_cursor, unicode_err = decode_unicode_escape(text, cursor + 2)
        if not next_cursor then
          return nil, nil, unicode_err
        end
        local ok, decoded = pcall(utf8.char, codepoint)
        if not ok then
          return nil, nil, "Invalid unicode escape in JSON string."
        end
        parts[#parts + 1] = decoded
        cursor = next_cursor
      else
        return nil, nil, "Invalid escape sequence in JSON string."
      end
    else
      parts[#parts + 1] = char
      cursor = cursor + 1
    end
  end

  return nil, nil, "Unterminated JSON string."
end

---@param text string
---@param index integer
---@return number|nil
---@return integer|nil
---@return string|nil
local function parse_number(text, index)
  local pattern = "^%-?%d+%.?%d*[eE]?[%+%-]?%d*"
  local fragment = text:sub(index)
  local match = fragment:match(pattern)
  if not match or match == "" or match == "-" then
    return nil, nil, "Invalid JSON number."
  end

  local value = tonumber(match)
  if value == nil then
    return nil, nil, "Invalid JSON number."
  end

  return value, index + #match, nil
end

---@param text string
---@param index integer
---@param literal string
---@param value any
---@return any
---@return integer|nil
---@return string|nil
local function parse_literal(text, index, literal, value)
  if text:sub(index, index + #literal - 1) ~= literal then
    return nil, nil, "Invalid JSON literal."
  end
  return value, index + #literal, nil
end

---@param text string
---@param index integer
---@return any
---@return integer|nil
---@return string|nil
local function parse_value(text, index)
  local cursor = skip_whitespace(text, index)
  local char = text:sub(cursor, cursor)

  if char == "{" then
    local object = {}
    cursor = skip_whitespace(text, cursor + 1)
    if text:sub(cursor, cursor) == "}" then
      return object, cursor + 1, nil
    end

    while cursor <= #text do
      if text:sub(cursor, cursor) ~= "\"" then
        return nil, nil, "Expected JSON object key."
      end
      local key, next_cursor, key_err = parse_string(text, cursor)
      if not next_cursor then
        return nil, nil, key_err
      end
      cursor = skip_whitespace(text, next_cursor)
      if text:sub(cursor, cursor) ~= ":" then
        return nil, nil, "Expected ':' after JSON object key."
      end
      local value, value_cursor, value_err = parse_value(text, cursor + 1)
      if not value_cursor then
        return nil, nil, value_err
      end
      object[key] = value
      cursor = skip_whitespace(text, value_cursor)
      local separator = text:sub(cursor, cursor)
      if separator == "}" then
        return object, cursor + 1, nil
      end
      if separator ~= "," then
        return nil, nil, "Expected ',' or '}' in JSON object."
      end
      cursor = skip_whitespace(text, cursor + 1)
    end

    return nil, nil, "Unterminated JSON object."
  end

  if char == "[" then
    local array = {}
    cursor = skip_whitespace(text, cursor + 1)
    if text:sub(cursor, cursor) == "]" then
      return array, cursor + 1, nil
    end

    local index_in_array = 1
    while cursor <= #text do
      local value, value_cursor, value_err = parse_value(text, cursor)
      if not value_cursor then
        return nil, nil, value_err
      end
      array[index_in_array] = value
      index_in_array = index_in_array + 1
      cursor = skip_whitespace(text, value_cursor)
      local separator = text:sub(cursor, cursor)
      if separator == "]" then
        return array, cursor + 1, nil
      end
      if separator ~= "," then
        return nil, nil, "Expected ',' or ']' in JSON array."
      end
      cursor = skip_whitespace(text, cursor + 1)
    end

    return nil, nil, "Unterminated JSON array."
  end

  if char == "\"" then
    return parse_string(text, cursor)
  end
  if char == "t" then
    return parse_literal(text, cursor, "true", true)
  end
  if char == "f" then
    return parse_literal(text, cursor, "false", false)
  end
  if char == "n" then
    return parse_literal(text, cursor, "null", nil)
  end

  return parse_number(text, cursor)
end

---@param value any
---@return string|nil
---@return string|nil
function JsonCodec.encode(value)
  return encode_value(value)
end

---@param text string
---@return any
---@return string|nil
function JsonCodec.decode(text)
  if type(text) ~= "string" then
    return nil, "JSON input must be a string."
  end

  local value, next_index, err = parse_value(text, 1)
  if not next_index then
    return nil, err
  end

  next_index = skip_whitespace(text, next_index)
  if next_index <= #text then
    return nil, "Unexpected trailing JSON content."
  end

  return value, nil
end

return JsonCodec
