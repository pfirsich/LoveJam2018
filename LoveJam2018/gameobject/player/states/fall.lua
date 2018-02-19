local const = require("constants")
local utils = require("utils")
local class = require("libs.class")

local states = require("gameobject.player.states.states")

local Fall = class("Fall", states.Base)

function Fall:initialize(player, ...)
    states.Base.initialize(self, player)
end

function Fall:enter()
    self.canFastFall = false
end

function Fall:exit(newState)

end

function Fall:update()
    local player = self.player

    if player.moveDir[2] < 1e-5 then
        self.canFastFall = true
    end

    -- gravity
    local maxFallSpeed = const.player.maxFallSpeed
    local gravity = const.player.maxFallSpeed / const.player.fallAccelDur

    -- ghetto fast fall
    if player.moveDir[2] > const.player.fastFallThresh then
        gravity = gravity * const.player.fastFallFactor
        maxFallSpeed = maxFallSpeed * const.player.fastFallFactor
    end

    if player.velocity[2] < maxFallSpeed then
        player.velocity[2] = player.velocity[2] + gravity * const.SIM_DT
    end

    if player.velocity[2] > 0 and player.animation.current ~= "fall" then
        player.animation:play("fall")
    end

    -- aerial movement
    local moveX = player.moveDir[1]
    local drift = utils.math.sign(moveX) * const.player.airAccelerationMin + moveX * const.player.airAcceleration
    local targetSpeed = const.player.airMaxMoveSpeed * moveX

    local max, min = math.max, math.min
    local dt = const.SIM_DT

    if player.velocity[1] >= 0 then
        -- moving right
        if player.velocity[1] > targetSpeed then
            -- too fast, self.velocity[1] has to become more negative
            -- you may "help" the friction by drifting, whichever is stronger
            local acceleration = min(-const.player.airFriction, drift)
            -- but don't go past targetSpeed, don't become *too* negative
            player.velocity[1] = max(player.velocity[1] + acceleration * dt, targetSpeed)
        else
            -- too slow, player.velocity[1] has to become more positive
            -- targetSpeed >= player.velocity[1] >= 0
            -- <=> drift >= 0 (because of leftstick)
            player.velocity[1] = min(player.velocity[1] + drift * dt, targetSpeed)
        end
    else
        -- same as above, but flipped signs
        -- moving left
        if player.velocity[1] < targetSpeed then
            -- too fast, player.velocity[1] has to become more positive
            local acceleration = max(const.player.airFriction, drift)
            -- ... but not *too* positive
            player.velocity[1] = min(player.velocity[1] + acceleration * dt, targetSpeed)
        else
            -- too slow, player.velocity[1] has to become more negative
            -- targetSpeed <= player.velocity[1] <= 0, drift <= 0
            player.velocity[1] = max(player.velocity[1] + drift * dt, targetSpeed)
        end
    end

    if player:enterDash() then
        return
    end

    if player:onGround() then
        player:setState(states.Wait)
    end

    if player.controller.attack.pressed then
        player:setState(states.Attack)
        return
    end

    player:interact()
end

return Fall
