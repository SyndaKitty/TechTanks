local menu = {}

local gui = require "Gspot"
local enet = require "enet"


function getIP()
    if menu.IP then
        return menu.IP
    end

    if not menu.IPThread then
        menu.IPThread = love.thread.newThread(love.filesystem.newFileData("ip.lua"))
        menu.IPThread:start()
    end

    if not menu.IPThread:isRunning() then
        local error = menu.IPThread:getError()
        if error then
            print("Error: " .. error)
        else
            menu.IP = love.thread.getChannel("ip"):pop()
        end

        menu.IPThread:release()
        menu.IPThread = nil
    end

    return menu.IP or ""
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

function bottomY(element)
    local c = containerPos(element)
    element.pos.y = c.y + c.h - element.pos.h
end
-- endregion


function menu:enter()
    getIP()

    menu.network = {
        status = nil
    }
    menu.channels = {
        fromNetwork = love.thread.getChannel("fromNetwork"),
        log = love.thread.getChannel("log"),
        error = love.thread.getChannel("error")
    }

    gui.style.font = love.graphics.newFont("res/VenusPlant.otf", 48)

    menu.hostJoinGrp = gui:group(nil, {0, 128, 600, 256})

    menu.hostBtn = gui:button("Host", { 0, 0, 300, 128}, menu.hostJoinGrp)
    menu.hostBtn.click = startHost

    menu.hostGrp = gui:group(nil, {0, 128, 900, 250})
    menu.hostCenterDiv = gui:group(nil, {0, 0, 900, 250}, menu.hostGrp)
    menu.hostTxt = gui:text("Awaiting Opponent...", {0, -40, 800, 700}, menu.hostCenterDiv)
    menu.hostErrTxt = gui:text("", {0, 0, 1200, 800 })
    -- menu.ipCopyBtn = gui:button()

    menu.hostBackBtn = gui:button("Back", {0, 0, 250, 100})
    menu.hostBackBtn.click = function()
        menu.hostGrp:hide()
        menu.hostBackBtn:hide()
        menu.hostJoinGrp:show()
        menu.hostErrTxt:hide()
        menu.hostErrTxt.label = ""
        stopConnecting()
        playOneShot("res/Blip.wav")
    end

    menu.hostGrp:hide()
    menu.hostBackBtn:hide()


    menu.joinBtn = gui:button("Join", { 316, 0, 300, 128}, menu.hostJoinGrp)
    menu.joinBtn.click = showJoinScreen

    menu.joinGrp = gui:group(nil, {0, 128, 600, 100})
    menu.joinIpTxt = gui:input("IP: ", {y = 0, w = 650, h = 100}, menu.joinGrp)
    menu.joinIpTxt.done = startClient

    menu.joinBackBtn = gui:button("Back", {300, 0, 250, 100})
    menu.joinBackBtn.click = function()
        menu.joinGrp:hide()
        menu.joinBackBtn:hide()
        menu.hostJoinGrp:show()
        menu.joinConnectBtn:hide()
        menu.joinIpTxt.value = ""
        playOneShot("res/Blip.wav")
        
        menu.connectTxt:hide()
        menu.connectBackBtn:hide()
        stopConnecting()
    end

    menu.joinConnectBtn = gui:button("Connect", {600, 0, 350, 100})
    menu.joinConnectBtn.click = startClient

    menu.joinGrp:hide()
    menu.joinBackBtn:hide()
    menu.joinConnectBtn:hide()

    menu.connectTxt = gui:text("Connecting", {0, 0, 450, 100}, nil)
    menu.connectTxt:hide()

    menu.connectErrTxt = gui:text("", {0, 0, 1200, 800}, nil)
    menu.connectErrTxt:hide()

    menu.connectBackBtn = gui:button("Back", {450, 700, 250, 100})
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
        stopConnecting()
    end
end


function showJoinScreen()
    menu.hostJoinGrp:hide()
    menu.joinGrp:show()
    menu.joinBackBtn:show()
    menu.joinConnectBtn:show()
    menu.joinIpTxt:focus()
    playOneShot("res/Blip.wav")
end


function startClient()
    local ip = menu.joinIpTxt.value
    print("Attempting to connect to " .. ip)

    menu.joinGrp:hide()
    menu.joinBackBtn:hide()
    menu.joinConnectBtn:hide()

    menu.connectTxt:show()
    menu.connectBackBtn:show()

    playOneShot("res/Blip.wav")
    startConnecting(ip)
end


function startHost()
    menu.hostJoinGrp:hide()
    menu.hostGrp:show()
    menu.hostBackBtn:show()
    playOneShot("res/Blip.wav")
    startConnecting()
end


function stopConnecting()
    if menu.network.thread and menu.network.thread:isRunning() then
        print("Stopping network thread")
        local gameChannel = love.thread.getChannel("fromGame")
        gameChannel:push("abort")
        menu.network.thread:wait()
        menu.network.thread:release()
        menu.channels.fromNetwork:clear()
        menu.channels.error:clear()
    end
    menu.network.thread = nil
end


function startConnecting(ip)
    menu.network.isServer = ip == nil
    if menu.network.thread then
        stopConnecting()
    end

    menu.network.thread = love.thread.newThread(love.filesystem.newFileData("network.lua"))
    menu.network.thread:start(ip)

    print("Started network thread")
end


function menu:draw()
    shrinkFit(menu.hostJoinGrp)
    center(menu.hostJoinGrp)
    center(menu.hostGrp)

    if not menu.network.status then
        menu.hostTxt.label = "Awaiting Opponent...\nYour IP is: " .. getIP()
    else
        menu.hostTxt.label = menu.network.status
    end
    
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

    local msg = menu.channels.log:pop()
    while msg do
        print(msg)
        msg = menu.channels.log:pop()
    end

    local msg = menu.channels.error:pop()
    while msg do
        local _,index = string.find(msg.error, ".*():")
        local body
        if index then
            body = string.sub(msg.error, index + 1)
        else
            body = msg.error
        end
        if menu.isServer then
            menu.hostErrTxt.label = body
            menu.hostErrTxt:show()
            menu.hostGrp:hide()
        else
            menu.connectErrTxt.label = body
            menu.connectErrTxt:show()
            menu.connectTxt:hide()
        end
        print(msg.error)
        msg = menu.channels.error:pop()
    end

    local msg = menu.channels.fromNetwork:pop()
    while msg do
        if msg == "Connecting" then
            menu.network.status = msg
        elseif msg == "Connected" then
            menu.network.status = msg
        elseif msg == "Start" then
            Game.initNetwork(menu.network)
            Gamestate.switch(Game)
        elseif msg == "Disconnected" then
            menu.network.status = nil
        end
        msg = menu.channels.fromNetwork:pop()
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