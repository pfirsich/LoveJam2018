local const = require("constants")
local class = require("libs.class")
local states = require("gameobject.player.states.states")

local Wait = class("Wait", states.Base)

function Wait:initialize(player, ...)
    states.Base.initialize(self, player)
end

function Wait:enter()

end

function Wait:exit(newState)

end

function Wait:update()
    local player = self.player

    player:friction(const.player.waitFriction)

    if player.controller.jump.pressed then
        player:setState(states.JumpSquat)
        return
    end

    if player:enterDash() then
        return
    end

    if math.abs(player.moveDir[1]) > 0 then
        player:setState(states.Run)
        return
    end

    if not player:onGround() then
        player:setState(states.Fall)
        return
    end
end

return Wait
