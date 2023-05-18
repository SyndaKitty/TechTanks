if arg[2] == "debug" then
    require("lldebugger").start()
end

-- Libraries
Gamestate = require "hump.gamestate"


-- Scenes
Game = require "game"
Menu = require "menu"


function love.load(args)
    Gamestate.registerEvents({'draw', 'update', 'keypressed', 'textinput', 'mousepressed', 'mousereleased', 'quit' })
    Menu.initArgs(args)
    Gamestate.switch(Menu)
end

Panic = love.threaderror

function love.threaderror(thread, errorstr)
    local gs = Gamestate.current()
    if gs and gs.threaderror then
        gs.threaderror(thread, errorstr)
    end
end


function love.errorhandler(msg)
    local gs = Gamestate.current()
    if gs.errorhandler then
        gs.errorhandler(msg)
    end
end