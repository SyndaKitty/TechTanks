local enet = require "enet"
local bitser = require "bitser"

local host = enet.host_create("localhost:49620", 1)
local fromHost = love.thread.getChannel('fromHost')
local fromGame = love.thread.getChannel('fromGameToHost')
local log = love.thread.getChannel('log')

local initialInfo = {
    command = "VerifyVersion",
    version = require "version",
}

while true do
    local msg = fromGame:pop()
    if msg == "abort" then
        return
    end

    local event = host:service(50)
    if not event then

    elseif event.type == "connect" then
        log:push("Host: Client connected")
        event.peer:send(bitser.dumps(initialInfo))
    elseif event.type == "disconnect" then
        log:push("Host: Client disconnected")
    elseif event.type == "receive" then
        log:push("Host: Received message")
    end
end