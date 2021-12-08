require 'Util'
require 'Player'

Map = Class{}

TILE_BRICK = 1
TILE_EMPTY = 4

CLOUD_LEFT = 6
CLOUD_RIGHT = 7

BUSH_LEFT = 2
BUSH_RIGHT = 3

MUSHROM_TOP = 10
MUSHROM_BOTTOM = 11

FLAG_TOP = 8
FLAG_MID = 12
FLAG_BOTTOM = 16
COCKADE_A = 13
COCKADE_B = 14
COCKADE_C = 15

JUMP_BLOCK = 5
JUMP_BLOCK_HIT = 9


local SCROLL_SPEED = 100

function Map:init()
    self.spritesheet = love.graphics.newImage('graphics/spritesheet.png')
    
    self.flagPlace = 35

    self.tileWidth = 16
    self.tileHeight = 16
    self.mapWidth = 200
    self.mapHeight = 28
    self.tiles = {}
    self.flagPoz = self.mapWidth

    self.player = Player(self)

    self.camX = 0
    self.camY = -3
    
    -- generate a quad (individual frame/sprite) for each tile
    self.tileSprites = generateQuads(self.spritesheet, self.tileWidth, self.tileHeight)

    self.animations = {
        ['flagup'] = Animation {
            texture = self.spritesheet,
            frames = {
                self.tileSprites[13],
                self.tileSprites[14],
            },
            interval = 0.4
        }, 
        ['flagd'] = Animation {
            texture = self.spritesheet,
            frames = {
                self.tileSprites[15],
                
            },
            interval = 0.4
        }
    }

    self.animation = self.animations['flagup']

    self.mapWidthPixels = self.mapWidth * self.tileWidth
    self.mapHeightPixels = self.mapHeight * self.tileHeight

    -- filling the map with empty tiles 
    for y = 1, self.mapHeight do 
        for x = 1, self.mapWidth do 
            self:setTile(x, y, TILE_EMPTY)
        end
    end

    local x = 1
    while x < self.mapWidth do

        if x < self.mapWidth - 2 then
            if math.random(20) == 1 then
                local cloudStart = math.random(self.mapHeight / 2 - 6)

                self:setTile(x, cloudStart, CLOUD_LEFT)
                self:setTile(x + 1, cloudStart, CLOUD_RIGHT)
            end
        end

        if math.random(20) == 1 and x < self.mapWidth - 22 then
            self:setTile(x, self.mapHeight / 2 - 2, MUSHROM_TOP)
            self:setTile(x, self.mapHeight / 2 - 1, MUSHROM_BOTTOM)

            for y = self.mapHeight / 2, self.mapHeight do 
                self:setTile(x, y, TILE_BRICK)
            end
            x = x + 1
        
        
        elseif math.random(10) == 1 and x < self.mapWidth - 22 then
            local bushLevel = self.mapHeight / 2 - 1

            self:setTile(x, bushLevel, BUSH_LEFT)
            for y = self.mapHeight / 2, self.mapHeight do
                self:setTile(x, y, TILE_BRICK)
            end
            x = x + 1

            self:setTile(x, bushLevel, BUSH_RIGHT)
            for y = self.mapHeight / 2, self.mapHeight do
                self:setTile(x, y, TILE_BRICK)
            end
            x = x + 1

        elseif math.random(14) ~= 1 then

            for y = self.mapHeight / 2, self.mapHeight / 1.5 do
                self:setTile(x, y, TILE_BRICK)
            end

            if math.random(20) == 1 and x < self.mapWidth - 22 then
                self:setTile(x, self.mapHeight / 2 - 4, JUMP_BLOCK)
            end

            x = x + 1
        elseif x < self.mapWidth - 22 then
            x = x + 2

        elseif x > self.mapWidth - 22 then

            for y = self.mapHeight / 2, self.mapHeight do
                self:setTile(x - 10, y, TILE_BRICK)
            end
        end

        
    end
    local n = 1
    while n < 10 do
        for y = self.mapWidth - 22, self.mapWidth - 12 - n  do   
            self:setTile(y + n, self.mapHeight / 2 - n, TILE_BRICK)
            self:setTile(self.mapWidth - 4, self.mapHeight / 2 - n - 1, FLAG_MID)
            self:setTile(self.mapWidth - 4, self.mapHeight / 2 - 1, FLAG_BOTTOM)
            self:setTile(self.mapWidth - 4, self.mapHeight / 2 - 11, FLAG_TOP)
            

            
            for j = self.mapHeight / 2, self.mapHeight do
                self:setTile(y + 14, j, TILE_BRICK)
            end
        end

        n = n + 1
    end

end

function Map:collides(tile)

    local collidables = {
        TILE_BRICK, JUMP_BLOCK, JUMP_BLOCK_HIT, MUSHROM_TOP, MUSHROM_BOTTOM
    }

    for _, v in ipairs(collidables) do
        if tile.id == v then
            return true
        end
    end

    return false
end

function Map:wincoll(tile)
    local collidables = {
        FLAG_TOP, FLAG_MID, FLAG_BOTTOM
    }

    for _, v in ipairs(collidables) do
        if tile.id == v then
            return true
        end
    end

    return false
end

function Map:update(dt)
    self.player:update(dt)
    self.animation:update(dt)

    self.camX = math.max(0,
        math.min(self.player.x - VIRTUAL_WIDTH / 2,
        math.min(self.mapWidthPixels - VIRTUAL_WIDTH, self.player.x)))

end

function Map:getTile(x, y)
    return self.tiles[(y - 1) * self.mapWidth + x]
end

function Map:tileAt(x, y)
    return {
        x = math.floor(x / self.tileWidth) + 1,
        y = math.floor(y / self.tileHeight) + 1,
        id = self:getTile(math.floor(x / self.tileWidth) + 1, math.floor(y / self.tileHeight) + 1)
    }
end

function Map:setTile(x, y, tile)
    self.tiles[(y - 1) * self.mapWidth + x] = tile
end



function Map:render()
    for y = 1, self.mapHeight do 
        for x = 1, self.mapWidth do
            love.graphics.draw(self.spritesheet, self.tileSprites[self:getTile(x, y)],
                (x - 1) * self.tileWidth, (y - 1) * self.tileHeight)
        end
    end

    if self.player.state == 'lose' then
        love.graphics.print("U lose! hahaha! Continue? Y or N", self.camX + 2, 100)
        love.graphics.print("another map? R", self.camX + 2, 120)
    end

    if self.player.state == 'win' then
        love.graphics.print("U WIN! Next map? Y or N", self.camX + 2, 100)
    end
    
    -- flag poz and anim
    love.graphics.draw(self.spritesheet, self.animation:getCurrentFrame(),
    self.mapWidthPixels - 69, self.flagPlace)
    
    self.player:render()
end