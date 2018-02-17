local utils = require("utils")
local const = require("constants")
local class = require("libs.class")
local vmath = require("utils.vmath")

local states = require("gameobject.player.states.states")

local Parry = class("Parry", states.Base)

function Parry:initialize(player, ...)
    states.Base.initialize(self, player)
end

function Parry:enter()
    self.player.velocity = {0, 0}
    self.player.invincibility = const.player.parryInvinc
end

function Parry:exit(newState)

end

function Parry:update()
    local player = self.player

    if player.time - self.start > const.player.parryDuration then
        player:setState(states.Fall)
        return
    end
end

return Parry
