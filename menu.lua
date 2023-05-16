local menu = {}

local gui = require "Gspot"
local enet = require "enet"

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
    menu.hostBackBtn:show()

    startHosting()
end

function join()
    menu.action = "join"
    menu.hostJoinGrp:hide()
    menu.joinGrp:show()
    menu.joinBackBtn:show()
    menu.joinConnectBtn:show()
end


function menu:enter()
    getIP()

    menu.network = {
        fromHost = love.thread.getChannel('fromHost'),
        fromClient = love.thread.getChannel('fromClient'),

    }

    gui.style.font = love.graphics.newFont("res/VenusPlant.otf", 48)

    menu.hostJoinGrp = gui:group(nil, {0, 128, 600, 256})

    menu.hostBtn = gui:button('Host', { 0, 0, 300, 128}, menu.hostJoinGrp)
    menu.hostBtn.click = host

    menu.hostGrp = gui:group(nil, {0, 128, 900, 250})
    menu.hostCenterDiv = gui:group(nil, {0, 0, 900, 250}, menu.hostGrp)
    menu.hostTxt = gui:text('Awaiting Opponent...', {0, -40, 800, 700}, menu.hostCenterDiv)
    -- menu.ipCopyBtn = gui:button()

    menu.hostBackBtn = gui:button('Back', {0, 0, 250, 100})
    menu.hostBackBtn.click = function()
        menu.hostGrp:hide()
        menu.hostBackBtn:hide()
        menu.hostJoinGrp:show()
        stopHosting()
        menu.action = nil
    end

    menu.hostGrp:hide()
    menu.hostBackBtn:hide()


    menu.joinBtn = gui:button('Join', { 316, 0, 300, 128}, menu.hostJoinGrp)
    menu.joinBtn.click = join

    menu.joinGrp = gui:group(nil, {0, 128, 600, 100})
    menu.joinIpTxt = gui:input("IP: ", {y = 0, w = 650, h = 100}, menu.joinGrp)
    menu.joinIpTxt.done = tryConnect

    menu.joinBackBtn = gui:button('Back', {300, 0, 250, 100})
    menu.joinBackBtn.click = function()
        menu.joinGrp:hide()
        menu.joinBackBtn:hide()
        menu.hostJoinGrp:show()
        menu.joinConnectBtn:hide()
        menu.joinIpTxt.value = ""
        menu.action = nil
        stopConnecting()
    end

    menu.joinConnectBtn = gui:button('Connect', {600, 0, 350, 100})
    menu.joinConnectBtn.click = tryConnect

    menu.joinGrp:hide()
    menu.joinBackBtn:hide()
    menu.joinConnectBtn:hide()

    menu.connectTxt = gui:text('')
end

function tryConnect()
    local ip = menu.joinIpTxt.value
    print("Attempting to connect to " .. ip)

    menu.joinGrp:hide()
    menu.joinBackBtn:hide()
    menu.joinConnectBtn:hide()

    menu.action = "connect"
    menu.opponentIP = ip

    startConnecting(ip)
end


-- region Gui helpers
function centerX(element)
    local cp = containerPos(element)

    local w, _ = element.pos.w, element.pos.h
    element.pos.x = (cp.w - w) / 2
end

function centerY(element)
    local cp = containerPos(element)

    local _, h = element.pos.w, element.pos.h
    element.pos.y = (cp.h - h) / 2
end

function center(element)
    centerX(element)
    centerY(element)
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

function followY(element, predecessor, spacing)
    if not spacing then spacing = 0 end
    element.pos.y = predecessor.pos.y + predecessor.pos.h + spacing
end
-- endregion

function stopConnecting()
    if menu.clientThread and menu.clientThread:isRunning() then
        print("Closing down existing clientThread")
        local gameChannel = love.thread.getChannel('fromGameToClient')
        gameChannel:push('abort')
        menu.hostThread:wait()
        menu.hostThread:release()
    end
    menu.clientThread = nil
end

function startConnecting(ip)
    if menu.clientThread then
        stopConnecting()
    end

    menu.clientThread = love.thread.newThread(love.filesystem.newFileData('client.lua'))
    menu.clientThread:start()

    love.thread.getChannel('fromGameToClient'):push(ip)

    print('Started client')
end

function stopHosting()
    if menu.hostThread and menu.hostThread:isRunning() then
        print('Closing down existing hostThread')
        local gameChannel = love.thread.getChannel('fromGameToHost')
        gameChannel:push('abort')
        menu.hostThread:wait()
        menu.hostThread:release()
    end
    menu.hostThread = nil
end

function startHosting()
    if menu.hostThread then
        stopHosting()
    end

    menu.hostThread = love.thread.newThread(love.filesystem.newFileData('host.lua'))
    menu.hostThread:start()

    print("Started host")
end

function menu:draw()
    shrinkFit(menu.hostJoinGrp)
    center(menu.hostJoinGrp)
    center(menu.hostGrp)

    menu.hostTxt.label = 'Awaiting Opponent...\nYour IP is: ' .. getIP()
    shrinkFit(menu.hostCenterDiv)
    center(menu.hostCenterDiv)

    followY(menu.hostBackBtn, menu.hostGrp, 16)
    centerX(menu.hostBackBtn)

    center(menu.joinGrp)
    followY(menu.joinBackBtn, menu.joinGrp, 16)
    followY(menu.joinConnectBtn, menu.joinGrp, 16)
    menu.joinBackBtn.pos.x = menu.joinGrp.pos.x
    menu.joinConnectBtn.pos.x = menu.joinGrp.pos.x + 300

    gui:draw()
    love.graphics.print("Menu", 0, 0)
end

function menu:update(dt)
    gui:update(dt)

    if not menu.log then
        menu.log = love.thread.getChannel('log')
    end
    local msg = menu.log:pop()
    while msg do
        print(msg)
        msg = menu.log:pop()
    end
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
    gui:keypress(key, scancode, isrepeat)
end

return menu