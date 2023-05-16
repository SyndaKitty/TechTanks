local enet = require "enet"
local bitser = require "bitser"

local fromClient = love.thread.getChannel('fromClient')
local fromGame = love.thread.getChannel('fromGameToClient')
local log = love.thread.getChannel('log')

local host = enet.host_create()

local ip = fromGame:demand()
local server = host:connect(ip .. ":49620")

local commands = {}
local version = require "version"

commands.VerifyVersion = function()

end

while true do
    local msg = fromGame:pop()
    if msg == "abort" then
        return
    end

    local event = host:service(50)
    if not event then

    elseif event.type == "connect" then
        log:push("Client: Connected")
    elseif event.type == "disconnect" then
        log:push("Client: Disconnected")
    elseif event.type == "receive" then
        log:push("Client: Received message")
        local message = bitser.loads(event.data)
        if not message then
            log:push("Client: Malformed message: " .. event.data)
        else
            log:push("Client: " .. message.command)
            commands[message.command](message)
        end
    end
end