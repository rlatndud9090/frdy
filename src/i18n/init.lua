--- Internationalization module
---@class i18n
local i18n = {}

local current_locale = "en"
local strings = {}

---@param locale string
---@param data table
function i18n.load(locale, data)
  strings[locale] = data
end

---@param locale string
function i18n.set_locale(locale)
  if strings[locale] then
    current_locale = locale
  end
end

---@return string
function i18n.get_locale()
  return current_locale
end

---@return table list of {key, label} for available locales
function i18n.get_available_locales()
  local locales = {}
  for locale, data in pairs(strings) do
    local label = data["locale.self"] or locale
    table.insert(locales, {key = locale, label = label})
  end
  table.sort(locales, function(a, b) return a.key < b.key end)
  return locales
end

--- Translate a key, with optional interpolation
---@param key string
---@param params table|nil
---@return string
function i18n.t(key, params)
  local text = nil

  -- Try current locale
  local locale_strings = strings[current_locale]
  if locale_strings and locale_strings[key] then
    text = locale_strings[key]
  end

  -- Fallback to English
  if not text and current_locale ~= "en" then
    local en = strings["en"]
    if en and en[key] then
      text = en[key]
    end
  end

  -- Last resort: return key
  if not text then
    return key
  end

  -- Interpolation: replace {name} with params.name
  if params then
    text = text:gsub("{(%w+)}", function(k)
      return params[k] ~= nil and tostring(params[k]) or ("{" .. k .. "}")
    end)
  end

  return text
end

return i18n
