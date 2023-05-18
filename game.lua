local bitser = require "bitser"
local pprint = require "pprint"

local game = {}
local maps = {
    "Map01.png",
    "Map02.png",
    "Map03.png",
    "Map04.png"
}

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


function selectMap()
    local possibleMaps = {}
    for _,map in ipairs(maps) do
        if not game.selectedMaps[map] then
            possibleMaps[#possibleMaps + 1] = map
        end
    end

    if #possibleMaps == 0 then
        game.selectedMaps = {}
        selectMap()
        return
    end

    game.state.map = math.random(#possibleMaps)
    game.selectedMaps[#game.selectedMaps + 1] = possibleMaps[game.state.map]
end


function startRound()
    game.state.map = selectMap()
end


function endRound()
    game.state.shells = {}
    game.state.tanks = {}
end


function sendStart()
    game.channels.fromGame:push({
        command = "Start",
        data = {
            game.state
        }
    })
end


function sendGameState()
    game.channels.fromGame:push({
        command = "State",
        data = {
            game.state
        }
    })
end


function startGame(state)
    if state then
        game.state = state[1]
    else
        game.state = {
            roundsWon = 0,
            roundsLost = 0,
            shells = {},
            tanks = {},
            waitTimeLeft = 3,
        }
        game.selectedMaps = {}
        startRound()
        sendStart()
    end
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
    if game.network.isServer then
        game.networkLogFile = "log-server"
        startGame()
    else
        game.networkLogFile = "log-client"
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
    if not s then return end

    if not game.state.unlocked then
        local timeLeftBefore = math.ceil(s.waitTimeLeft)
        s.waitTimeLeft = s.waitTimeLeft - dt
        local timeLeftAfter = math.ceil(s.waitTimeLeft)

        if timeLeftAfter < timeLeftBefore then
            if timeLeftAfter > 0 then
                print(timeLeftAfter)
                playSound("res/Beep1.wav")
            else
                print("Begin!")
                playSound("res/Beep2.wav")
                game.state.unlocked = true
            end
        end
    else
        
    end
end


function game.handleNetwork()
    local msg = game.channels.networkLog:pop()
    while msg do
        --print(love.filesystem.append(game.networkLogFile, bitser.dumps(msg)))
        print(pprint.pformat(msg))
        msg = game.channels.networkLog:pop()
    end

    local msg = game.channels.fromNetwork:pop()
    while msg do
        if msg == "Disconnected" then
            Gamestate.pop("Opponent Retreated")
            return
        elseif msg.command == "Start" then
            startGame(msg.data)
        elseif msg.command == "State" then
            game.state = msg.data
        end
        msg = game.channels.fromNetwork:pop()
    end
end


function game:update(dt)
    game.handleLogs()
    game.handleErrors()

    game.handleGame(dt)
    game.handleNetwork()
end


function game:draw()

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