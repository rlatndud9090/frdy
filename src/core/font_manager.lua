--- Font manager for loading and providing Korean-capable fonts
---@class FontManager
local FontManager = {}

local fonts = {}
local FONT_PATH = "assets/fonts/NotoSansKR-Regular.ttf"

local SIZES = {
  small = 12,
  medium = 16,
  large = 20,
  title = 24,
}

function FontManager.init()
  for name, size in pairs(SIZES) do
    fonts[name] = love.graphics.newFont(FONT_PATH, size)
  end
  love.graphics.setFont(fonts.medium)
end

---@param name string "small"|"medium"|"large"|"title"
---@return love.Font
function FontManager.get(name)
  return fonts[name] or fonts.medium
end

return FontManager
