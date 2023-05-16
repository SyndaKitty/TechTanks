local enet = require "enet"
local bitser = require "bitser"

local ip = ...
local isServer = ip == nil
local running = true
local exitCode
local version = require "version"
local peer
local channels = {
    fromNetwork = love.thread.getChannel("fromNetwork"),
    fromGame = love.thread.getChannel("fromGame"),
    log = love.thread.getChannel("log"),
    error = love.thread.getChannel("error")
}
local commands = {}


function respond(msg)
    assert(msg)
    assert(msg.command)
    assert(peer)

    channels.log:push("Sending message " .. msg.command)
    peer:send(bitser.dumps(msg))
end


function sendVerifyVersion(peer)
    respond({
        command = "VerifyVersion",
        data = {
            require "version"
        }
    })
end


commands.VerifyVersion = function(data, peer)
    if data[1] ~= version then
        running = false
        exitCode = "Version mismatch"
        return
    end

    if isServer then
        channels.fromNetwork:push("Start")
    else
        sendVerifyVersion(peer)
        channels.fromNetwork:push("Start")
    end
end


function connect(p)
    peer = p
    channels.log:push("Peer connected " .. peer:connect_id())
    channels.fromNetwork:push("Connecting")

    if isServer then
        sendVerifyVersion(peer)
    end
end


function disconnect(p)
    channels.log:push("Peer disconnected " .. peer:connect_id())
    channels.fromNetwork:push("Disconnected")
    peer = nil

    if not isServer then
        exitCode = "Player Disconnected"
        running = false
    end
end


function handleEvent(event)
    if not event then

    elseif event.type == "connect" then
        connect(event.peer)
    elseif event.type == "disconnect" then
        disconnect(event.peer)
    elseif event.type == "receive" then
        local message = bitser.loads(event.data)
        if not message then
            channels.log.push("Malformed message: " .. event.data)
        else
            channels.log:push("Received message " .. message.command)
            commands[message.command](message.data, event.peer)
        end
    end
end

local status, error = pcall(function()
    local host

    if isServer then
        host = enet.host_create("localhost:49620", 1)
        if not host then
            exitCode = "Unable to open port"
            return
        end
    else
        host = enet.host_create()
        host:connect(ip .. ":49620")
        local event = host:service(5000)
        
        if not event then
            exitCode = "Could not establish connection"
            return
        end
        handleEvent(event)
    end

    while true do
        if not running then
            return
        end
        
        local msg = channels.fromGame:pop()
        if msg == "abort" then
            peer:disconnect()
            host:flush()
            return
        end

        local event = host:service(50)
        while event do
            handleEvent(event)
            event = host:service()
        end
    end
end)

if not status then
    channels.error:push({
        threadName = "Network",
        error = error
    })
elseif exitCode then
    channels.error:push({
        threadName = "Network",
        error = exitCode
    })
end