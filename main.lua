WINDOW_WIDTH = 1280
WINDOW_HEIGHT = 720

VIRTUAL_WIDTH = 432
VIRTUAL_HEIGHT = 243

LIFES = 3
COINS = 0

push = require 'push'
Class = require 'class'

require 'Util'
require 'Map'

function love.load()
    
    math.randomseed(os.time())

    map = Map()
    
    love.graphics.setDefaultFilter('nearest', 'nearest')

    push:setupScreen(VIRTUAL_WIDTH, VIRTUAL_HEIGHT, WINDOW_WIDTH, WINDOW_HEIGHT, {
        fullscreen = false,
        resizable = false,
        vsync = true,
    })

    love.keyboard.keysPressed = {}

    
end

function love.keypressed(key)
    if key == 'escape' then
        love.event.quit()
    end

    love.keyboard.keysPressed[key] = true
end

function love.keyboard.wasPressed(key)
    return love.keyboard.keysPressed[key]
end

function love.update(dt)
    map:update(dt)

    love.keyboard.keysPressed = {}
end

-- called each frame, used to render to the screen 
function love.draw()
    -- begin virtual resolution drawing
    push:apply('start')
    
   
    love.graphics.translate(math.floor(-map.camX), math.floor(-map.camY))

    -- clear screen using Mario background blue
    love.graphics.clear(108/255, 140/255, 1, 1)

    -- renders our map object onto the screen
    map:render()

    displayScore()

    -- end virtual resolution
    push:apply('end')
end
-- Display scores // 
function displayScore()
    love.graphics.print(LIFES .. " lifes", map.camX + 2, 2)
    love.graphics.print(COINS .. " coins", map.camX + 2, 15)
    
end 