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
    playOneShot("res/Blip.wav")
    startHosting()
end

function join()
    menu.action = "join"
    menu.hostJoinGrp:hide()
    menu.joinGrp:show()
    menu.joinBackBtn:show()
    menu.joinConnectBtn:show()
    playOneShot("res/Blip.wav")
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
        playOneShot("res/Blip.wav")
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
        playOneShot("res/Blip.wav")
        
        menu.connectTxt:hide()
        menu.connectBackBtn:hide()
        stopConnecting()
    end

    menu.joinConnectBtn = gui:button('Connect', {600, 0, 350, 100})
    menu.joinConnectBtn.click = tryConnect

    menu.joinGrp:hide()
    menu.joinBackBtn:hide()
    menu.joinConnectBtn:hide()

    menu.connectTxt = gui:text('Connecting', {0, 0, 450, 100}, nil)
    menu.connectTxt:hide()

    menu.connectErrTxt = gui:text('', {0, 0, 1200, 800}, nil)
    menu.connectErrTxt:hide()

    menu.connectBackBtn = gui:button('Back', {450, 700, 250, 100})
    menu.connectBackBtn:hide()
    menu.connectBackBtn.click = function()
        menu.connectTxt:hide()
        menu.connectBackBtn:hide()
        menu.joinGrp:show()
        menu.joinBackBtn:show()
        menu.joinConnectBtn:show()
        menu.connectErrTxt:hide()
        menu.connectErrTxt.label = ""
        playOneShot("res/Blip.wav")
    end
end

function tryConnect()
    local ip = menu.joinIpTxt.value
    print("Attempting to connect to " .. ip)

    menu.joinGrp:hide()
    menu.joinBackBtn:hide()
    menu.joinConnectBtn:hide()

    menu.action = "connect"

    menu.connectTxt:show()
    menu.connectBackBtn:show()

    playOneShot("res/Blip.wav")
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

function stretchY(element)
    local cp = containerPos(element)
    element.pos.h = cp.h
end

function followY(element, predecessor, spacing)
    if not spacing then spacing = 0 end
    element.pos.y = predecessor.pos.y + predecessor.pos.h + spacing
end
-- endregion

function bottomY(element)
    local c = containerPos(element)
    element.pos.y = c.y + c.h - element.pos.h
end

function stopConnecting()
    if menu.network.clientThread and menu.network.clientThread:isRunning() then
        print("Closing down existing clientThread")
        local gameChannel = love.thread.getChannel('fromGameToClient')
        gameChannel:push('abort')
        menu.network.clientThread:wait()
        menu.network.clientThread:release()
    end
    menu.network.clientThread = nil
end

function startConnecting(ip)
    if menu.network.clientThread then
        stopConnecting()
    end

    menu.network.clientThread = love.thread.newThread(love.filesystem.newFileData('client.lua'))
    menu.network.clientThread:start(ip)

    print('Started client')
end

function stopHosting()
    if menu.network.hostThread and menu.network.hostThread:isRunning() then
        print('Closing down existing hostThread')
        local gameChannel = love.thread.getChannel('fromGameToHost')
        gameChannel:push('abort')
        menu.network.hostThread:wait()
        menu.network.hostThread:release()
    end
    menu.network.hostThread = nil
end

function startHosting()
    if menu.network.hostThread then
        stopHosting()
    end

    menu.network.hostThread = love.thread.newThread(love.filesystem.newFileData('host.lua'))
    menu.network.hostThread:start()

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

    centerX(menu.connectTxt)
    centerY(menu.connectTxt)

    stretchX(menu.connectErrTxt)
    stretchY(menu.connectErrTxt)

    centerX(menu.connectBackBtn)
    bottomY(menu.connectBackBtn)

    gui:draw()
    love.graphics.print("Menu", 0, 0)
end

function menu:update(dt)
    gui:update(dt)

    if not menu.log then
        menu.log = love.thread.getChannel('log')
    end
    if not menu.error then
        menu.error = love.thread.getChannel('error')
    end

    local msg = menu.log:pop()
    while msg do
        print(msg)
        msg = menu.log:pop()
    end

    local msg = menu.error:pop()
    while msg do
        if msg.threadName == "Client" then
            local _,index = string.find(msg.error, ".*():")
            local body = string.sub(msg.error, index + 1)

            menu.connectErrTxt.label = body
            menu.connectErrTxt:show()
            menu.connectTxt:hide()
        end
        print(msg.error)
        msg = menu.error:pop()
    end
end

function playOneShot(sound)
    menu.sounds = menu.sounds or {}
    if not menu.sounds[sound] then
        local src = love.audio.newSource(sound, "static")
        src:setVolume(1)
        menu.sounds[sound] = src
    end
    menu.sounds[sound]:play()
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

function menu.threaderror(thread, errorstr)
    error(errorstr)
end

return menu