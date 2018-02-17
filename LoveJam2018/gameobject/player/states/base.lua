local utils = require("utils")
local class = require("libs.class")

local PlayerState = class("PlayerState")

function PlayerState:initialize(player)
    self.player = player
    self.start = player.time
end

function PlayerState:enter()
end

function PlayerState:update()
end

function PlayerState:exit(newState)
end

function PlayerState:collision(other, mtv)
end

-- for multiplayer
function PlayerState:serialize()
    return nil
end

function PlayerState:deserialize(serialized)
    -- pass
end

function PlayerState:tostring()
    local tab = "    "
    local s = "{\n"
    s = s .. tab .. "class = " .. self.class.name .. ",\n"
    for k, v in pairs(self) do
        if not utils.table.inList({"player", "class", "start"}, k) then
            s = s .. tab .. k .. " = " .. tostring(v) .. ",\n"
        end
    end
    return s .. "}"
end

return PlayerState
