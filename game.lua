local pprint = require "pprint"
local maps = require "maps"

local game = {}


function disconnect()
    if game.network.thread then
        print("Stopping network thread")
        game.channels.fromGame:push("abort")
        game.network.thread:wait()
        game.network.thread:release()
    end
    game.channels.fromNetwork:clear()
    game.channels.error:clear()
end


function refreshMapPool()
    game.mapPool = {}
    for _,m in ipairs(maps.files) do
        print(m.index .. " " .. m.name)
        game.mapPool[#game.mapPool+1] = m
    end
end


function selectMap()
    if not game.mapPool or #game.mapPool == 0 then
        refreshMapPool()
    end

    if not game.network.isServer then
        game.mapEntry = game.mapPool[game.state.mapIndex]
        return
    elseif game.mapEntry then
        return
    end

    local index = love.math.random(#game.mapPool)
    game.mapEntry = table.remove(game.mapPool, index)
    game.state.mapIndex = game.mapEntry.index
end


function startRound()
    if game.network.isServer then
        game.waitTimeLeft = 3
    else
        -- enet seems to overestimate ping at first, so to ensure client doesn't get too far ahead
        -- we divide ping by 4 instead of 2
        -- discrepancy could be due to clumsy not delaying messages symmetrically though
        game.waitTimeLeft = 3 - game.ping / 4
    end

    selectMap()
    game.world = love.physics.newWorld()
    game.map = maps.instantiate(game.mapEntry.name, game.world)
end


function endRound()
    game.state.shells = {}
    game.state.tanks = {}
    game.mapName = nil
    game.world:destroy()
    game.world = nil
    game.state.mapIndex = nil
end


function sendStart()
    print("sendStart")
    game.channels.fromGame:push({
        command = "Start",
        data = game.state
    })
end


function sendGameState()
    game.channels.fromGame:push({
        command = "State",
        data = game.state
    })
end


function startGame(state)
    print("startGame")
    if state then
        game.state = state
    else
        game.state = {
            roundsWon = 0,
            roundsLost = 0,
            shells = {},
            tanks = {},
        }
        game.lastUpdateSent = 0
        game.networkUpdateInterval = 0.1
        selectMap()
        sendStart()
    end
    startRound()
    playSound("res/Beep1.wav")
    print(3)
end


function playSound(sound)
    game.sounds = game.sounds or {}
    if not game.sounds[sound] then
        local src = love.audio.newSource(sound, "static")
        src:setVolume(1)
        game.sounds[sound] = src
    end
    game.sounds[sound]:play()
end


function game:enter()
    game.channels = {
        fromGame = love.thread.getChannel("fromGame"),
        fromNetwork = love.thread.getChannel("fromNetwork"),
        error = love.thread.getChannel("error"),
        log = love.thread.getChannel("log"),
        networkLog = love.thread.getChannel("networkLog")
    }
    game.ping = .1 -- A guess
    if game.network.isServer then
        startGame()
    end
end


function game.handleLogs()
    local msg = game.channels.log:pop()
    while msg do
        print(msg)
        msg = game.channels.log:pop()
    end
end


function game.handleErrors()
    local msg = game.channels.error:pop()
    if msg then
        local _,index = string.find(msg.error, ".*():")
        local body
        if index then
            body = string.sub(msg.error, index + 1)
        else
            body = msg.error
        end
        print(msg.error)
        Gamestate.pop(body)
    end
end


function game.handleGame(dt)
    local s = game.state
    local n = game.network
    if not s then return end

    if not s.unlocked then
        local timeLeftBefore = math.ceil(game.waitTimeLeft)
        game.waitTimeLeft = game.waitTimeLeft - dt
        local timeLeftAfter = math.ceil(game.waitTimeLeft)

        if timeLeftAfter < timeLeftBefore then
            if timeLeftAfter > 0 then
                print(timeLeftAfter)
                playSound("res/Beep1.wav")
            else
                print("Begin!")
                playSound("res/Beep2.wav")
                s.unlocked = true
            end
        end
    else
        if n.isServer then
            game.lastUpdateSent = game.lastUpdateSent + dt
            if game.lastUpdateSent > game.networkUpdateInterval then
                sendGameState()
                game.lastUpdateSent = game.lastUpdateSent - game.networkUpdateInterval
            end
        end
    end
end


function game.handleNetwork()
    local msg = game.channels.networkLog:pop()
    while msg do
        pprint.pprint(msg)
        msg = game.channels.networkLog:pop()
    end

    local msg = game.channels.fromNetwork:pop()
    while msg do
        if type(msg) == "string" then
            if msg == "Disconnected" then
                Gamestate.pop("Opponent Retreated")
                return
            end
        elseif type(msg) == "table" then
            if msg.command == "Start" then
                startGame(msg.data)
            elseif msg.command == "State" then
                game.state = msg.data
            end
        elseif type(msg) == "number" then
            -- Ping
            game.ping = msg / 1000
        end
        msg = game.channels.fromNetwork:pop()
    end
end


function game:update(dt)
    -- game.handleLogs()
    game.handleErrors()

    game.handleGame(dt)
    game.handleNetwork()
end


function game:draw()
    love.graphics.clear(1, 1, 1)

    local w,h = love.graphics.getDimensions()
    local scale = math.min(w/1200, h/800)
    local paddingX = (w / scale - 1200) / 2
    local paddingY = (h / scale - 800) / 2

    love.graphics.scale(scale)
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("fill", 0, 0, paddingX, h)
    love.graphics.rectangle("fill", 0, 0, w, paddingY)
    love.graphics.rectangle("fill", w/scale-paddingX, 0, w, h)
    love.graphics.rectangle("fill", 0, h/scale-paddingY, w, paddingY)

    love.graphics.translate(paddingX, paddingY)

    if game.map then
        love.graphics.setColor(0, 0, 0)
        for _,b in ipairs(game.map.blocks) do
            love.graphics.rectangle("fill", b.x * 40, b.y * 40, b.w * 40, b.h * 40)
        end
    end
end


function game.initNetwork(networkData)
    game.network = networkData
end


function game:wheelmoved(x, y)
	
end


function game:keypressed(key, scancode, isrepeat)
    
end


function game.threaderror(thread, errorstr)
    
end


function game.errorhandler(msg)
    print(msg)
    Gamestate.pop(msg)
end


function game.quit()
    disconnect()
end


return game