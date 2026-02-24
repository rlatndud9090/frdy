local FontManager = require('src.core.font_manager')
local i18n = require('src.i18n.init')
local Game = require('src.core.game')

local function is_ci_check_mode()
  local env = os.getenv("FRDY_CI_CHECK")
  return env == "1" or env == "true" or env == "TRUE"
end

function love.load()
  FontManager.init()

  i18n.load("en", require('src.i18n.locales.en'))
  i18n.load("ko", require('src.i18n.locales.ko'))
  i18n.set_locale("en")

  Game:getInstance():init()

  if is_ci_check_mode() and love.window and love.window.minimize then
    love.window.minimize()
  end
end

function love.update(dt)
  Game:getInstance():update(dt)
end

function love.draw()
  Game:getInstance():draw()
end

function love.keypressed(key)
  Game:getInstance():keypressed(key)
end

function love.mousepressed(x, y, button)
  Game:getInstance():mousepressed(x, y, button)
end

function love.wheelmoved(x, y)
  Game:getInstance():wheelmoved(x, y)
end
