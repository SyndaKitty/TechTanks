local socket = require "socket"
local host = "api.ipify.org"
local path = "/"
local conn = assert(socket.tcp())
conn:connect(host, 80)
conn:send("GET " .. path .. " HTTP/1.1\r\nHost: " .. host .. "\r\nConnection: close\r\n\r\n")
local response = conn:receive("*a")
local _,index = string.find(response, "\r\n\r\n")
local body = string.sub(response, index + 1)
conn:close()
love.thread.getChannel('ip'):push(body)