local Game = require('src.core.game')

function love.load()
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
