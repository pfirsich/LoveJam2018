local utils = require("utils")
local const = require("constants")
local class = require("libs.class")
local vmath = require("utils.vmath")

local states = require("gameobject.player.states.states")

local Dash = class("Dash", states.Base)

function Dash:initialize(player, ...)
    states.Base.initialize(self, player)
end

-- speed(t) = startSpeed - friction * t
-- speed(duration) = 0
-- <=> friction = startSpeed / duration
-- s(t) = startSpeed*t - 0.5 * friction * t^2
-- s(t) = startSpeed * (t - 0.5 * t^2 / duration)
-- distance = s(duration) = startSpeed * (duration - 0.5 * duration) = startSpeed * 0.5 * duration
-- startSpeed = 2 * distance / duration

function Dash:enter()
    local player = self.player
    local startSpeed = 2 * const.player.dashDistance / const.player.dashDuration
        + const.player.dashStartSpeedRemainder
    player.velocity = vmath.mul(vmath.normed(player.moveDir), startSpeed)
    self.friction = startSpeed / const.player.dashDuration
    player.canDash = false
end

function Dash:exit(newState)

end

function Dash:update()
    local player = self.player

    player:friction(self.friction, self.friction)

    if player.time - self.start > const.player.dashDuration then
        player:setState(states.Fall)
        return
    end

    player:interact()
end

function Dash:collision(other, mtv)
    local player = self.player
    if player:onGround() then
        player:setState(states.Wavedash)
    else
        player:setState(states.Cling)
    end
end

return Dash
