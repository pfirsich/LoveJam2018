local msgpack = require("libs.MessagePack")
local console = require("libs.console")
require("enet")

local utils = require("utils")
local GameObject = require("gameobject")
local map = require("map")
local net = require("net")
local game = require("scenes.game")

local server = {}

server.players = {}
server.maxPlayers = 10

local peerIdMap = {}
local peerIdCounter = utils.counter()

local msgHandlers = {}

function server.start(port)
    lg.setBackgroundColor(0, 0, 0)
    console.textColor = {0, 255, 0}

    game.loadMap("foyer")
    -- server owns all level objects
    for _, object in ipairs(GameObject.world) do
        object.owned = true
    end

    console.print(("Hosting on port %d (UDP)."):format(port))
    server.host = enet.host_create("*:" .. port)
    if not server.host then
        error(("Could not host on port %d!"):format(port))
    end
    server.host:compress_with_range_coder()
end

function server.update()
    local event = server.host:service()
    while event do
        if event.type == "connect" then
            peerIdMap[event.peer] = peerIdCounter:get()
        elseif event.type == "disconnect" then
            -- TODO
            local peerId = peerIdMap[event.peer]
        elseif event.type == "receive" then
            local data = msgpack.unpack(event.data)
            msgHandlers[data.T](event.peer, data)
        end
        event = server.host:service()
    end

    for _, object in ipairs(GameObject.world) do
        if object.dynamic and object.owned then
            object:update()
        end
    end
    GameObject.removeMarked()

    server.host:broadcast(net.wrapArguments(net.msgTypes.S.UPDATE, {state = net.getWorldUpdate()}))
end

local function getOpenTeams()
    -- TODO: implement this properly
    return {"attackers", "defenders", "spectate"}
end

local function nicknameTaken(nickname)
    for peerId, player in pairs(server.players) do
        if player.nickname == nickname then
            return true
        end
    end
    return false
end

local function fixNickname(nickname)
    if nickname:len() > 32 then
        nickname = nickname:sub(1, 32)
    end
    if nicknameTaken(nickname) then
        local suffix = 1
        while nicknameTaken(nickname .. ("(%d)"):format(suffix)) do
            suffix = suffix + 1
        end
    else
        return nickname
    end
end

-- lvl in {"system", "admin", "other"}
local function sendChat(msg, lvl)
    console.print(("(%s) %s"):format(lvl, msg))
    server.host:broadcast(net.wrapArguments(
        net.msgTypes.S.CHAT, {msg = msg, lvl = lvl or "admin"}))
end

msgHandlers[net.msgTypes.C.CONNECT] = function(peer, msg)
    if #utils.table.keys(server.players) < server.maxPlayers then
        local peerId = peerIdMap[peer]
        assert(not server.players[peerId])
        local resp = {
            playerId = peerId,
            nickname = fixNickname(msg.nickname),
            teams = getOpenTeams(),
            map = game.mapData.name,
            state = net.getWorldUpdate(),
        }
        net.send(peer, net.msgTypes.S.ACCEPT, resp)
        console.print(("'%s' is connecting."):format(resp.nickname))
    else
        net.send(peer, net.msgTypes.S.DENY, {reason = "The server is full."})
    end
end

msgHandlers[net.msgTypes.C.NICKNAME] = function(peer, msg)
    local player = server.players[peerIdMap[peer]]
    if player then
        local oldNickname = player.nickname
        player.nickname = nil
        local nickname = fixNickname(msg.nickname)
        player.nickname = nickname
        net.send(peer, net.msgTypes.S.NICKNAME, {nickname = nickname})
        sendChat(("'%s' has changed their nickname to '%s'"):
            format(oldNickname, nickname), "system")
    end
end

msgHandlers[net.msgTypes.C.TEAMS] = function(peer, msg)
    net.send(peer, net.msgTypes.S.NICKNAME, {teams = getOpenTeams()})
end

msgHandlers[net.msgTypes.C.CHAT] = function(peer, msg)
    local player = server.players[peerIdMap[peer]]
    if player then
        sendChat(player.nickname .. ": " .. msg.msg, "other")
    end
end

msgHandlers[net.msgTypes.C.JOIN] = function(peer, msg)
    local player = server.players[peerIdMap[peer]]
    if player then
        sendChat("", "other")
    end
end

msgHandlers[net.msgTypes.C.UPDATE] = function(peer, msg)
    net.applyWorldUpdate(msg.state, peerIdMap[peer])
end

return server
