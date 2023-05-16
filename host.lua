local enet = require "enet"
local bitser = require "bitser"

local status, error = pcall(function()
    local host = enet.host_create("localhost:49620", 1)
    if not host then
        error("Unable to open port")
    end

    local fromHost = love.thread.getChannel('fromHost')
    local fromGame = love.thread.getChannel('fromGameToHost')
    local log = love.thread.getChannel('log')

    local verifyVersion = {
        command = "VerifyVersion",
        data = {
            require "version"
        }
    }

    local commands = {}
    
    commands.VerifyVersion = function()

    end

    local peerState = {}

    function connect(peer)
        peerState[peer:connect_id()] = {
            verifiedVersion = false,
            peer = peer
        }

        peer:send(bitser.dumps(verifyVersion))
        fromHost:push("Connecting")
    end

    function disconnect(peer)
        peerState[peer:connect_id()] = nil
        fromHost:push("Disconnected")
    end

    function processMessage(connectId, message)
        local s = peerState[connectId]
        if message.command == "VerifyVersion" then
            if message.data == "true" then
                s.verifiedVersion = true
                log:push("Host: Verified version")
                fromHost:push("Connected")
            else
                error("Version mismatch")
            end
        end

        if not s.verifiedVersion then return end
    end

    while true do
        local msg = fromGame:pop()
        if msg == "abort" then
            return
        end

        local event = host:service(50)
        if not event then

        elseif event.type == "connect" then
            log:push("Host: Client connected " .. event.data)
            connect(event.peer)
        elseif event.type == "disconnect" then
            log:push("Host: Client disconnected " .. event.data)
            disconnect(event.peer)
        elseif event.type == "receive" then
            log:push("Host: Received message")
            processMessage(event.peer:connect_id(), event.data)
        end
    end
end)

if not status then
    love.thread.getChannel('error'):push({
        threadName = "Host",
        error = error
    })
else
    -- Returned without error
end