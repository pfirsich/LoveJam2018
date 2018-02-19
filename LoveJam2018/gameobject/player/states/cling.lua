local const = require("constants")
local utils = require("utils")
local vmath = require("utils.vmath")
local class = require("libs.class")
local states = require("gameobject.player.states.states")
local GameObject = require("gameobject")
local HCshapes = require("libs.HC.shapes")
local audio = require("audio")

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
    self.lastCollided = {}
    self.clingType = "V"
    self.stepAccumulator = 0
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

    if vmath.len(player.velocity) < 1e-5 then
        player.animation:ensure("climb" .. self.clingType .. "stop")
        -- so it won't trigger this frame, but the one after that immediately
        self.stepAccumulator = const.player.clingStepInterval - const.SIM_DT * 1.5
    else
        player.animation:ensure("climb" .. self.clingType)
    end

    self.stepAccumulator = self.stepAccumulator + const.SIM_DT
    if self.stepAccumulator > const.player.clingStepInterval then
        audio.play("step", player.position)
        self.stepAccumulator = 0
    end

    if player:onGround() and player.velocity[2] > 0 then
        player:setState(states.Wait)
        return
    end

    if player.controller.jump.pressed then
        if self.clingType == "V" then
            player.animation:play("jump")
            local vel = vmath.copy(const.player.clingWalljumpVel)
            if not player.flipped then
                vel[1] = -vel[1]
            end
            player.velocity = vel
            player.flipped = not player.flipped
        end
        player:setState(states.Fall)
        return
    end

    -- cling direction
    self.clingProbe:moveTo(unpack(player.position))
    local collisions = GameObject.collider:collisions(self.clingProbe)
    local collisionTypes = {}
    for other, mtv in pairs(collisions) do
        if other._object.class == Polygon and other._object.solid and other._object.climbable then
            local normal = {mtv.x, mtv.y}
            if math.abs(normal[1]) > math.abs(normal[2]) * 0.5 then
                collisionTypes[normal[1] > 0 and "L" or "R"] = true
            else
                collisionTypes[normal[2] > 0 and "U" or "D"] = true
            end
        end
    end
    collisionTypes["LR"] = collisionTypes.L or collisionTypes.R

    if collisionTypes.LR and not collisionTypes.U then
        self.clingType = "V"
    elseif not collisionTypes.LR and collisionTypes.U then
        self.clingType = "H"
    elseif collisionTypes.LR and collisionTypes.U then
        -- only handle this case if either LR or U just joined!
        -- if neither joined this frame, keep what we have
        if not self.lastCollided.LR then
            self.clingType = "V"
        end
        if not self.lastCollided.U then
            self.clingType = "H"
        end
    else -- neither
        player:setState(states.Fall) -- drop
        return
    end

    if self.clingType == "V" then
        player.flipped = collisionTypes.L or false
    else
        player:updateFlipped()
    end

    for _, dir in ipairs({"L", "R", "LR", "U", "D"}) do
        self.lastCollided[dir] = collisionTypes[dir]
    end

    player:interact()
end

return Cling
