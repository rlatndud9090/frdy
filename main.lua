local FontManager = require('src.core.font_manager')
local i18n = require('src.i18n.init')
local Game = require('src.core.game')

function love.load()
  FontManager.init()

  i18n.load("en", require('src.i18n.locales.en'))
  i18n.load("ko", require('src.i18n.locales.ko'))
  i18n.set_locale("en")

  Game:getInstance():init()
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
