if arg[2] == "debug" then
    require("lldebugger").start()
end

-- Libraries
Gamestate = require "hump.gamestate"
local bitser = require "bitser"
local enet = require "enet"


-- Scenes
Game = require "game"
Menu = require "menu"


function love.load()
    Gamestate.registerEvents({'draw', 'update', 'keypressed', 'textinput', 'mousepressed', 'mousereleased', 'quit' })
    Gamestate.switch(Menu)
end

Panic = love.threaderror

function love.threaderror(thread, errorstr)
    local gs = Gamestate.current()
    if gs and gs.threaderror then
        gs.threaderror(thread, errorstr)
    end
end