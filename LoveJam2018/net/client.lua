local msgpack = require("libs.MessagePack")
local console = require("libs.console")
require("enet")

local config = require("config")
local net = require("net")
local GameObject = require("gameobject")
local scenes = require("scenes")

local client = {}

client.playerId = nil
client.connected = false

local msgHandlers = {}

function client.connect(addr)
    console.print(("Connecting to %s..."):format(addr))
    client.host = enet.host_create()
    client.host:compress_with_range_coder()
    client.server = client.host:connect(addr)
end

function client.update()
    local event = client.host:service()
    while event do
        if event.type == "connect" then
            net.send(event.peer, net.msgTypes.C.CONNECT, {nickname = config.nickname})
        elseif event.type == "disconnect" then
            error("Disconnected.")
        elseif event.type == "receive" then
            local data = msgpack.unpack(event.data)
            msgHandlers[data.T](data)
        end
        event = client.host:service()
    end

    for _, object in ipairs(GameObject.world) do
        if object.dynamic and object.owned then
            object:update()
        end
    end
    GameObject.removeMarked()

    -- send update
    net.send(client.server, net.msgTypes.C.UPDATE, {state = net.getWorldUpdate(true)})
end

local function teamScreen(teams)
    local options = {}
    console.chooseOption("", teams, function(i, option)
        scenes.game.joinTeam(option)
        console.active = false
    end)
end

msgHandlers[net.msgTypes.S.DENY] = function(msg)
    error("Connection denied. Reason: " .. msg.reason)
end

msgHandlers[net.msgTypes.S.ACCEPT] = function(msg)
    client.playerId = msg.playerId
    client.serverNickname = msg.nickname
    scenes.game.loadMap(msg.map)
    net.applyWorldUpdate(msg.state)
    teamScreen(msg.teams)
    client.connected = true
end

msgHandlers[net.msgTypes.S.NICKNAME] = function(msg)
    if scenes.game.player then
        scenes.game.player.nickname = msg.nickname
        client.serverNickname = msg.nickname
    end
end

msgHandlers[net.msgTypes.S.TEAMS] = function(msg)
    teamScreen(msg.teams)
end

msgHandlers[net.msgTypes.S.MAP] = function(msg)

end

msgHandlers[net.msgTypes.S.CHAT] = function(msg)

end

msgHandlers[net.msgTypes.S.PLAYERS] = function(msg)

end

msgHandlers[net.msgTypes.S.ROUND_START] = function(msg)

end

msgHandlers[net.msgTypes.S.ROUND_END] = function(msg)

end

msgHandlers[net.msgTypes.S.UPDATE] = function(msg)
    net.applyWorldUpdate(msg.state)
end

return client
