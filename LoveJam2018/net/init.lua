local msgpack = require("libs.MessagePack")
require("enet")

local utils = require("utils")
local GameObject = require("gameobject")

local net = {}

net.msgTypes = {
    S = utils.table.enum({ -- server
        "DENY", -- reason
        "ACCEPT", -- send playerId, send nickname back, possible teams to join (atk, def, spec), map to load, state diff
        "NICKNAME", -- send nickname back
        "TEAMS", -- possible teams to join
        "MAP", -- load new map
        "CHAT", -- level (system, admin, other(user chat))
        "PLAYERS", -- list of players (nick, team) (also send on team change)
        "ROUND_START", -- empty
        "ROUND_END", -- empty
        "UPDATE",
    }),
    C = utils.table.enum({ -- client
        "CONNECT", -- send nickname
        "NICKNAME", -- send new nickname
        "TEAMS", -- empty
        "CHAT", -- message
        "JOIN", -- team
        "UPDATE",
    })
}

function net.serializeFields(obj, fields)
    local ser = {obj.class.name}
    local i = 2
    for _, field in ipairs(fields) do
        ser[i] = obj[field]
        i = i + 1
    end
    return ser
end

function net.getSerializedField(fields, serialized, field)
    local i = utils.table.indexOf(fields, field)
    assert(i, field)
    return serialized[i+1] -- +1 because of class.name
end

function net.deserializeFields(obj, fields, serialized)
    assert(obj.class.name == serialized[1])
    local i = 2
    for _, field in ipairs(fields) do
        obj[field] = serialized[i]
        i = i + 1
    end
end

function net.applyWorldUpdate(state, senderPeerId)
    for id, object in pairs(state) do
        local localObj = GameObject.getById(id)
        if not localObj then
            local class = GameObject.classes[object[1]]
            assert(class, object[1])
            local obj = class.fromSerialization(object)
            obj:changeId(id)
            obj._owner = senderPeerId
        elseif not localObj.owned then
            localObj:deserialize(object)
        end
    end
end

function net.getWorldUpdate(onlyOwned)
    local state = {}
    for _, object in ipairs(GameObject.world) do
        if object.dynamic and object.serialize and (not onlyOwned or object.owned) then
            local ser = object:serialize()
            if ser then
                state[object.id] = ser
            end
        end
    end
    return state
end

function net.wrapArguments(msgType, data, flags)
    if flags == true then flags = "unreliable" end
    data.T = msgType
    if flags == "reliable" then
        data.R = true
    end
    return msgpack.pack(data), 0, flags
end

function net.send(peer, msgType, data, flags)
    if peer:state() == "connected" then
        peer:send(net.wrapArguments(msgType, data, flags))
    end
end

return net
