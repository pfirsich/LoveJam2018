local utils = require("utils")
local const = require("constants")
local class = require("libs.class")
local vmath = require("utils.vmath")

local states = require("gameobject.player.states.states")

local Wavedash = class("Wavedash", states.Base)

function Wavedash:initialize(player, ...)
    states.Base.initialize(self, player)
end

function Wavedash:enter()

end

function Wavedash:exit(newState)

end

function Wavedash:update()
    local player = self.player
    local friction = const.player.waitFriction * const.player.wavedashFrictionFactor
    player:friction(friction, friction)

    if not player:onGround() then
        player.velocity = vmath.mul(player.velocity, const.player.wavedashRunoffVelFactor)
        player:setState(states.Fall)
        return
    end

    if player.time - self.start > const.player.wavedashDuration then
        player:setState(states.Wait)
    end
end

return Wavedash
