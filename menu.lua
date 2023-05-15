local menu = {}

local gui = require "Gspot"

function getIP()
    if menu.IP then
        return menu.IP
    end

    if not menu.IPThread then
        menu.IPThread = love.thread.newThread(love.filesystem.newFileData('ip.lua'))
        menu.IPThread:start()
    end

    if not menu.IPThread:isRunning() then
        local error = menu.IPThread:getError()
        if error then
            print('Error: ' .. error)
        else
            menu.IP = love.thread.getChannel('ip'):pop()
        end

        menu.IPThread:release()
        menu.IPThread = nil
    end

    return menu.IP or ""
end


function host()
    menu.action = "host"
    menu.hostJoinGrp:hide()
    menu.hostGrp:show()
end

function join()
    menu.action = "join"
    menu.hostJoinGrp:hide()
end


function menu:enter()
    getIP()

    gui.style.font = love.graphics.newFont("res/VenusPlant.otf", 72)

    menu.hostJoinGrp = gui:group(nil, {0, 128, 600, 256})

    menu.hostBtn = gui:button('Host', { 0, 0, 300, 128}, menu.hostJoinGrp)
    menu.hostBtn.click = host

    menu.joinBtn = gui:button('Join', { 316, 0, 300, 128}, menu.hostJoinGrp)
    menu.joinBtn.click = join

    menu.hostGrp = gui:group(nil, {0, 128, 600, 256})
    menu.hostTxt = gui:text('Your IP is: ', {0, 128, 100, 100}, menu.hostGrp)
    menu.hostGrp:hide()
end



-- region Gui helpers
function center(element)
    local cp = containerPos(element)

    local pos = element.pos
    local w, h = pos.w, pos.h
    element.pos = { x = (cp.w - w) / 2, y = (cp.h - h) / 2, w = w, h = h }
end

function shrinkFit(element)
    local minX, minY, maxX, maxY = nil, nil, nil, nil
    for i,c in ipairs(element.children) do
        local leftX = c.pos.x
        local rightX = c.pos.x + c.pos.w
        local upY = c.pos.y
        local downY = c.pos.y + c.pos.h

        if minX == nil or leftX < minX then
            minX = leftX
        end
        if maxX == nil or rightX > maxX then
            maxX = rightX
        end
        if minY == nil or upY < minY then
            minY = upY
        end
        if maxY == nil or downY > maxY then
            maxY = downY
        end
    end

    element.pos.x = minX
    element.pos.w = maxX - minX
    element.pos.y = minY
    element.pos.h = maxY - minY
end

function containerPos(element)
    if element.parent then
        return element.parent.pos
    end
    local w, h = love.graphics.getDimensions()
    return { x = 0, y = 0, w = w, h = h }
end

function stretchX(element)
    local cp = containerPos(element)
    element.pos.w = cp.w
end
-- endregion

function menu:draw()
    shrinkFit(menu.hostJoinGrp)
    center(menu.hostJoinGrp)
    center(menu.hostGrp)
    center(menu.hostTxt)
    stretchX(menu.hostTxt)

    gui:draw()
    love.graphics.print("Menu", 0, 0)
end

function menu:update(dt)
    gui:update(dt)

    local ip = getIP()
    print(ip)
end

function menu:textinput(key)
    if gui.focus then
        gui:textinput(key)
    end
end

function menu:mousepressed(x, y, button)
    gui:mousepress(x, y, button)
end

function menu:mousereleased (x, y, button)
	gui:mouserelease(x, y, button)
end

function menu:wheelmoved(x, y)
	gui:mousewheel(x, y)
end

function menu:keypressed(key, scancode, isrepeat)
    
end

return menu