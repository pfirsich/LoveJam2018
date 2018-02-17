local const = require("constants")
local utils = require("utils")
local vmath = require("utils.vmath")
local class = require("libs.class")
local states = require("gameobject.player.states.states")
local GameObject = require("gameobject")
local HCshapes = require("libs.HC.shapes")

local Cling = class("Cling", states.Base)

function Cling:initialize(player, ...)
    states.Base.initialize(self, player)
end

function Cling:enter()
    self.player.velocity = {0, 0}
    local w, h = const.player.width + const.player.clingProbeMargin,
        const.player.height + const.player.clingProbeMargin
    self.clingProbe = HCshapes.newPolygonShape(0, 0,  w, 0,  w, h,  0, h)
    self.player.canDash = true
end

function Cling:exit(newState)

end

function Cling:update()
    local player = self.player

    -- movement
    local dir = vmath.copy(player.moveDir)
    -- per-axis deadzone
    if math.abs(dir[1]) < const.player.clingDeadzone then dir[1] = 0 end
    if math.abs(dir[2]) < const.player.clingDeadzone then dir[2] = 0 end

    local speed = const.player.clingSpeed
    if player.controller.sprint.state then
        speed = const.player.clingSprintSpeed
    end
    player.velocity = vmath.mul(dir, speed)

    -- end cling?
    self.clingProbe:moveTo(unpack(player.position))
    local colliding = false
    local collisions = GameObject.collider:collisions(self.clingProbe)
    print("cling", #utils.table.keys(collisions))
    for other, mtv in pairs(collisions) do
        if other._object.class == Polygon then
            colliding = true
        end
    end

    if player:onGround() then
        player:setState(states.Wait)
    end

    if not colliding then
        player:setState(states.Fall)
    end
end

return Cling
