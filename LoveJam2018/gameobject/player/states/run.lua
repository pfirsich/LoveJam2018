local utils = require("utils")
local const = require("constants")
local class = require("libs.class")

local states = require("gameobject.player.states.states")

local Run = class("Run", states.Base)

function Run:initialize(player, ...)
    states.Base.initialize(self, player)
end

function Run:enter()

end

function Run:exit(newState)

end

function Run:update()
    local player = self.player

    local moveX = player.moveDir[1]
    local accell = const.player.maxWalkSpeed / const.player.walkAccelDur
    local targetMoveSpeed = moveX * const.player.maxWalkSpeed
    if player.controller.sprint.state then
        targetMoveSpeed = targetMoveSpeed * const.player.maxSprintSpeedFactor
        accell = math.abs(targetMoveSpeed) / const.player.sprintAccelDur
    end

    if targetMoveSpeed > 0 and player.velocity[1] < targetMoveSpeed then
        player.velocity[1] = player.velocity[1] + accell * const.SIM_DT
    elseif targetMoveSpeed < 0 and player.velocity[1] > targetMoveSpeed then
        player.velocity[1] = player.velocity[1] - accell * const.SIM_DT
    else
        player:friction(const.player.runFriction)
    end

    if player:enterDash() then
        return
    end

    if player.controller.jump.pressed then
        player:setState(states.JumpSquat)
        return
    end

    if not player:onGround() then
        player:setState(states.Fall)
        return
    end

    if math.abs(player.velocity[1]) < const.player.runEndSpeed
            and math.abs(targetMoveSpeed) < const.player.runEndSpeed then
        player:setState(states.Wait)
        return
    end
end

return Run
