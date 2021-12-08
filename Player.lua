Player = Class{}

require 'Animation'

local MOVE_SPEED = 160
local JUMP_VELOCITY = 800
local GRAVITY = 40

function Player:init(map)
    self.width = 16
    self.height = 20
    self.map = map
    self.x = self.map.tileWidth * 1
    self.y = self.map.tileHeight * (self.map.mapHeight / 2 - 1) - self.height
    
    music = love.audio.newSource('sounds/music.wav', 'static')
    music:setLooping(true)
    music:setVolume(0.25)
    music:play()

    self.dx = 0
    self.dy = 0

    self.texture = love.graphics.newImage('graphics/blue_alien.png')
    self.frames = generateQuads(self.texture, self.width, self.height)

    self.state = 'idle'
    self.direction = 'right'

    self.sounds = {
        ['jump'] = love.audio.newSource('sounds/jump.wav', 'static'),
        ['hit'] = love.audio.newSource('sounds/hit.wav', 'static'),
        ['coin'] = love.audio.newSource('sounds/coin.wav', 'static'),
        ['win'] = love.audio.newSource('sounds/death.wav', 'static'),
    }

    self.animations = {
        ['idle'] = Animation {
            texture = self.texture,
            frames = {
                self.frames[1]
            },
            interval = 1
        },
        ['walking'] = Animation {
            texture = self.texture,
            frames = {
                self.frames[9], self.frames[10], self.frames[11]
            },
            interval = 0.15
        },
        ['jumping'] = Animation {
            texture = self.texture,
            frames = {
                self.frames[3]
            },
            interval = 1
        },
        ['win'] = Animation {
            texture = self.texture,
            frames = {
                self.frames[2],
                self.frames[3],
                self.frames[7],
                self.frames[6],

            },
            interval = 0.5
        }
    
    }

    self.animation = self.animations['idle']

    self.behaviors = {
        ['idle'] = function(dt)
            if love.keyboard.wasPressed('space') then
                self.dy = -JUMP_VELOCITY
                self.state = 'jumping'
                self.animation = self.animations['jumping']
                self.sounds['jump']:play()
            elseif love.keyboard.isDown('a') then
                self.direction = 'left'
                self.dx = -MOVE_SPEED
                self.state = 'walking'
                self.animations['walking']:restart()
                self.animation = self.animations['walking']
            elseif love.keyboard.isDown('d') then
                self.direction = 'right'
                self.dx = MOVE_SPEED
                self.state = 'walking'
                self.animations['walking']:restart()
                self.animation = self.animations['walking']
            else
                self.dx = 0
            end

            if not self.map:collides(self.map:tileAt(self.x, self.y + self.height)) and
                not self.map:collides(self.map:tileAt(self.x + self.width - 1, self.y + self.height)) then

                self.state = 'jumping'
                self.animation = self.animations['jumping']
            end
        end,
        ['walking'] = function(dt)
            if love.keyboard.wasPressed('space') then
                self.dy = -JUMP_VELOCITY
                self.state = 'jumping'
                self.animation = self.animations['jumping']
                self.sounds['jump']:play()
            elseif love.keyboard.isDown('a') then
                self.dx = -MOVE_SPEED
                self.direction = 'left'
            elseif love.keyboard.isDown('d') then
                self.dx = MOVE_SPEED
                self.direction = 'right'
            else
                self.dx = 0
                self.state = 'idle'
                self.animation = self.animations['idle']
            end

            self:checkRightCollision()
            self:checkLeftCollision()

            if not self.map:collides(self.map:tileAt(self.x, self.y + self.height)) and
                not self.map:collides(self.map:tileAt(self.x + self.width - 1, self.y + self.height)) then

                self.state = 'jumping'
                self.animation = self.animations['jumping']
            end
        end,
        ['jumping'] = function(dt)
            if self.y > 300 then
                return
            end
            if love.keyboard.isDown('a') then
                self.direction = 'left'
                self.dx = -MOVE_SPEED
            elseif love.keyboard.isDown('d') then
                self.direction = 'right'
                self.dx = MOVE_SPEED
            end

            self.dy = self.dy + GRAVITY
            if self.map:collides(self.map:tileAt(self.x, self.y + self.height)) or
                self.map:collides(self.map:tileAt(self.x + self.width - 1, self.y + self.height)) then

                self.dy = 0
                self.state = 'idle'
                self.animation = self.animations[self.state]
                self.y = (self.map:tileAt(self.x, self.y + self.height).y - 1) * self.map.tileHeight - self.height
            end

            self:checkRightCollision()
            self:checkLeftCollision()
            self:checkDead()
        end,
        ['win'] = function(dt)
            
            self.dy = 100
            self.direction = 'right'
            self.animation = self.animations['idle']
            map.flagPlace = math.min(VIRTUAL_HEIGHT / 2 + 50, map.flagPlace + self.dy * dt) 
            if self.map:collides(self.map:tileAt(self.x, self.y + self.height)) or
                self.map:collides(self.map:tileAt(self.x + self.width - 1, self.y + self.height)) then
                self.dy = 0
                self.animation = self.animations['win'] 
                
            end

            if love.keyboard.isDown('y') then
                self.state = 'idle'
                map:init()

            elseif love.keyboard.isDown('n') then
                love.event.quit()
            end
            
        end,
        ['lose'] = function(dt)
            music:stop()
            self.x = self.map.tileWidth * 1
            self.y = self.map.tileHeight * (self.map.mapHeight / 2 - 1) - self.height
            self.dy = 0
            self.dx = 0
            self.direction = 'right'
            self.animation = self.animations['idle']
            
            if love.keyboard.isDown('y') then
                self.state = 'idle'
                music:play()
            elseif love.keyboard.isDown('n') then
                love.event.quit()
            elseif love.keyboard.isDown('r') then
                map:init()
            end
            
        end
    }
end

function Player:update(dt)
    self.behaviors[self.state](dt)
    self.animation:update(dt)
    self.y = self.y + self.dy * dt
    self.x = self.x + self.dx * dt
    
    -- if we have negative y velocity (jump), check if we collide with any blocks above us 
    if self.dy < 0 then
        if self.map:tileAt(self.x, self.y).id ~= TILE_EMPTY or
            self.map:tileAt(self.x + self.width - 1, self.y).id ~= TILE_EMPTY  then

            local playCoin = false
            local playHit = false
            if self.map:tileAt(self.x, self.y).id == JUMP_BLOCK then
                self.map:setTile(math.floor(self.x / self.map.tileWidth) + 1,
                    math.floor(self.y / self.map.tileHeight) + 1, JUMP_BLOCK_HIT)
                    self.dy = 0
                    COINS = COINS + 1
                playCoin = true
            elseif self.map:tileAt(self.x, self.y).id == JUMP_BLOCK_HIT then
                playHit = true
                self.dy = 0
            end
            if self.map:tileAt(self.x + self.width - 1, self.y).id == JUMP_BLOCK then
                self.map:setTile(math.floor((self.x + self.width - 1) / self.map.tileWidth) + 1,
                    math.floor(self.y / self.map.tileHeight) + 1, JUMP_BLOCK_HIT)
                    self.dy = 0
                    COINS = COINS + 1
                playCoin = true
            elseif self.map:tileAt(self.x + self.width - 1, self.y).id ==  JUMP_BLOCK_HIT then
                playHit = true
                self.dy = 0
            end

            if COINS == 10 then
                LIFES = LIFES + 1
                COINS = 0
            end
            if playCoin then
                self.sounds['coin']:play()
            elseif playHit then
                self.sounds['hit']:play()
            end
        end
    end
end

function Player:checkLeftCollision()
    if self.dx < 0 then
        if self.map:collides(self.map:tileAt(self.x - 1, self.y)) or
            self.map:collides(self.map:tileAt(self.x - 1, self.y + self.height - 1)) then
            
            self.dx = 0
            self.x = self.map:tileAt(self.x - 1, self.y).x * self.map.tileWidth
        end
    end
end

function Player:checkRightCollision()
    if self.dx > 0 then
        if self.map:collides(self.map:tileAt(self.x + self.width, self.y)) or
            self.map:collides(self.map:tileAt(self.x + self.width, self.y + self.height - 1)) then
            
            self.dx = 0
            self.x = (self.map:tileAt(self.x + self.width, self.y).x - 1) * self.map.tileWidth - self.width
        end

        if self.map:wincoll(self.map:tileAt(self.x + self.width, self.y)) or
            self.map:wincoll(self.map:tileAt(self.x + self.width, self.y + self.height - 1)) then
            self.state = 'win'
            music:stop()
            self.sounds['win']:play()
            self.sounds['win']:play()
            self.sounds['win']:play()
            map.animation = map.animations['flagd']
            
            self.x = (self.map:tileAt(self.x + self.width, self.y).x) * self.map.tileWidth - self.width
            self.dx = 0
        end
    end
end

function Player:checkDead()
    if self.dy > 0 then
        if self.y > VIRTUAL_HEIGHT / 2 + self.height * 4 + map.tileHeight * 2 then
            LIFES = LIFES - 1
            if LIFES < 0 then
                love.event.quit()
            end
            self.state = 'lose'
        end
            
    end
    
end

function Player:render()

    local scaleX
    if self.direction == 'right' then
        scaleX = 1
    else
        scaleX = -1
    end

    
    love.graphics.draw(self.texture, self.animation:getCurrentFrame(),
        math.floor(self.x + self.width / 2), math.floor(self.y + self.height / 2),
         0, scaleX, 1,
        self.width / 2, self.height / 2)
end

