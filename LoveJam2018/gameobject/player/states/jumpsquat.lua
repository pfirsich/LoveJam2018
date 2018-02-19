local utils = require("utils")
local const = require("constants")
local class = require("libs.class")
local audio = require("audio")

local states = require("gameobject.player.states.states")

local JumpSquat = class("JumpSquat", states.Base)

function JumpSquat:initialize(player, ...)
    states.Base.initialize(self, player)
end

function JumpSquat:enter()
    self.player.animation:play("jumpsquat")
end

function JumpSquat:exit(newState)

end

function JumpSquat:update()
    local player = self.player

    player:friction(const.player.jumpSquatFriction)

    if player.time - self.start > const.player.jumpSquatDuration then
        local shorthop = not player.controller.jump.state
        local factor = 1.0
        if shorthop then
            factor = const.player.shorthopFactor
            audio.play("shorthop", player.position)
        else
            audio.play("jump", player.position)
        end
        player.velocity[2] = -const.player.jumpStartSpeed * factor

        player.velocity[1] = player.velocity[1] * const.player.groundToJumpMoveSpeedFactor
        player.velocity[1] = player.velocity[1] + player.moveDir[1] * const.player.jumpMoveDirSpeed
        player.velocity[1] = utils.math.clampAbs(player.velocity[1], const.player.jumpMaxMoveSpeed)

        player.animation:play("jump")
        player:setState(states.Fall)
    end
end

return JumpSquat
