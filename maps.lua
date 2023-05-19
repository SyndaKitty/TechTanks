local maps = {
    files = {
        { index=1, name="res/maps/Map01.png" },
        { index=2, name="res/maps/Map02.png" },
        { index=3, name="res/maps/Map03.png" },
        { index=4, name="res/maps/Map04.png" },
        { index=5, name="res/maps/Map05.png" }
    }
}

local mapWidth = 30
local mapHeight = 20


function maps.isPlayer(m, x, y)
    if m.tilesConsidered[y * mapWidth + x] then
        return false
    end
    local r, g, b = m.imageData:getPixel(x, y)
    if r == 1 and g == 0 then return 1 end
    if b == 1 and g == 0 then return 2 end
    return false
end


function maps.isWall(m, x, y)
    if m.tilesConsidered[y * mapWidth + x] then
        return false
    end
    local r, g, b = m.imageData:getPixel(x, y)
    return r == 0 and g == 0 and b == 0
end


function maps.newBlock(x, y, w, h)
    return {
        x = x,
        y = y,
        w = w,
        h = h,
        area = w * h
    }
end


function maps.addBlock(m, block)
    m.blocks[#m.blocks+1] = block
    for yi = block.y, block.y + block.h - 1 do
        for xi = block.x, block.x + block.w - 1 do
            m.tilesConsidered[yi * mapWidth + xi] = true
        end
    end
end


function maps.findBestBlockAt(m, x, y)
    local bestBlock
    local maxX = mapWidth

    if not maps.isWall(m, x, y) then
        return
    end

    local h = 0

    for yi = y, mapHeight-1 do
        if not maps.isWall(m, x, yi) then
            break
        end
        h = h + 1

        local w = 0
        for xi = x, maxX-1 do
            if not maps.isWall(m, xi, yi) then
                maxX = xi
                break
            else
                w = w + 1
            end
        end
        local nextBlock = maps.newBlock(x, y, w, h)
        if not bestBlock or nextBlock.area > bestBlock.area then
            bestBlock = nextBlock
        end
    end

    if bestBlock then
        maps.addBlock(m, bestBlock)
    end
end


function maps.readMapData(m)
    m.blocks = {}
    m.tilesConsidered = {}
    for y = 0,mapHeight-1 do
        for x = 0,mapWidth-1 do
            maps.findBestBlockAt(m, x, y)

            local p = maps.isPlayer(m, x, y)
            if p then
                m.players[p] = {
                    startingPos = { x + .75, y + .75 }
                }
            end
        end
    end
end


function maps.instantiate(mapName, world)
    print("Instantiating " .. mapName)
    if not maps[mapName] then
        maps[mapName] = {
            imageData = love.image.newImageData(mapName)
        }
    end

    local m = maps[mapName]
    m.world = world
    m.players = {}
    maps.readMapData(m)
    for _,b in ipairs(m.blocks) do
        b.body = love.physics.newBody(world, b.x + b.w / 2, b.y + b.h / 2, "static")
        local shape = love.physics.newRectangleShape(b.w, b.h)
        love.physics.newFixture(b.body, shape)
    end
    for i = 1,2 do
        local p = m.players[i]
        if p then
            p.body = love.physics.newBody(world, p.startingPos[1], p.startingPos[2], "dynamic")
            local shape = love.physics.newCircleShape(.75)
            love.physics.newFixture(p.body, shape)
        end
    end

    return m
end

return maps