local enet = require "enet"
local bitser = require "bitser"

local ip = ...
local status, error = pcall(function()
    local fromClient = love.thread.getChannel('fromClient')
    local fromGame = love.thread.getChannel('fromGameToClient')
    local log = love.thread.getChannel('log')

    local host = enet.host_create()

    local server = host:connect(ip .. ":49620")

    local commands = {}
    local version = require "version"

    function respond(peer, msg)
        log:push("Client: Sending " .. msg.command)
        peer:send(bitser.dumps(msg))
    end

    commands.VerifyVersion = function(data, peer)
        local response = {
            command = "VerifyVersion",
            data = "false"
        }
        if data[1] == version then
            response.data = "true"
            respond(peer, response)
        else
            respond(peer, response)
            peer:disconnect_later()
        end
    end

    -- Ensure connection
    local event = host:service(5000)

    if not event then
        error("Could not establish connection")
    end

    local hostState = {}

    function connect(peer)
        hostState[peer:connect_id()] = {
            verifiedVersion = false,
            host = host
        }
    end

    function disconnect(peer)
        hostState[peer:connect_id()] = nil
    end

    while true do
        local msg = fromGame:pop()
        if msg == "abort" then
            return
        end

        if not event then

        elseif event.type == "connect" then
            log:push("Client: Connected to host " .. event.data)
            connect(event.peer)
        elseif event.type == "disconnect" then
            log:push("Client: Disconnected from host " .. event.data)
            disconnect(event.peer)
        elseif event.type == "receive" then
            local message = bitser.loads(event.data)
            if not message then
                log:push("Client: Malformed message: " .. event.data)
            else
                log:push("Client: Received " .. message.command)
                commands[message.command](message.data, event.peer)
            end
        end

        event = host:service(50)
    end
end)

if not status then
    love.thread.getChannel('error'):push({
        threadName = "Client",
        error = error
    })
else
    -- Returned without error
end