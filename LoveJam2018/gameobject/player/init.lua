local class = require("libs.class")
local const = require("constants")
local utils = require("utils")
local vmath = require("utils.vmath")
local GameObject = require("gameobject")
local Polygon = require("gameobject.polygon")
local states = require("gameobject.player.states")
local HCshapes = require("libs.HC.shapes")
local fonts = require("media.fonts")
local camera = require("camera")

local Player = class("Player", GameObject)

function Player:initialize(controller, team, spawnPosition)
    GameObject.initialize(self)
    self.depth = 1
    self.controller = controller
    self.team = team
    self.position = spawnPosition
    self.velocity = {0, 0}
    self.shape = GameObject.collider:rectangle(0, 0, const.player.width, const.player.height)
    self.shape._object = self
    self.frameCounter = 0
    self.time = 0
    self.canDash = true
    self.invincibility = 0

    self:setState(states.Wait)

    local w, h = const.player.width * const.player.groundProbeWidthFactor, const.player.groundProbeHeight
    self._groundProbe = HCshapes.newPolygonShape(0, 0,  w, 0,  w, h,  0, h)
end

function Player:setState(stateClass, ...)
    local state = stateClass(self)
    if self.state then
        self.state:exit(state)
    end
    self.state = state
    self.state:enter(...)
end

function Player:enterDash()
    local onGround = self:onGround()
    if self.controller.dash.pressed and self.canDash then
        if vmath.len(self.moveDir) > 0.0 and (not onGround or self.moveDir[2] < 0.0) then
            self:setState(states.Dash)
            return true
        else
            self:setState(states.Parry)
            return true
        end
    else
        if onGround then
            self.canDash = true
        end
    end
end

function Player:move(dv)
    self:moveTo(vmath.add(self.position, dv))
end

function Player:moveTo(v)
    self.position = {unpack(v)}
    self.shape:moveTo(unpack(v))
end

local function linearFriction(v, f)
    if v > 0 then
        return math.max(0, v - f)
    else
        return math.min(0, v + f)
    end
end

function Player:friction(x, y)
    self.velocity[1] = linearFriction(self.velocity[1], (x or 0) * const.SIM_DT)
    self.velocity[2] = linearFriction(self.velocity[2], (y or 0) * const.SIM_DT)
end

function Player:onGround()
    self._groundProbe:moveTo(self.position[1],
        self.position[2] + const.player.height/2 +
        const.player.groundProbeHeight * 0.5 +
        const.player.groundProbeOffsetY)
    local collisions = GameObject.collider:collisions(self._groundProbe)
    for other, mtv in pairs(collisions) do
        if other._object.class == Polygon then
            return true
        end
    end
    return false
end

function Player:update()
    local pconst = const.player

    self.controller:update()
    self.moveDir = {self.controller.moveX.state, self.controller.moveY.state}
    if vmath.len(self.moveDir) < pconst.moveDeadzone then
        self.moveDir = {0, 0}
    else
        self.moveDir = vmath.mul(self.moveDir, vmath.len(self.moveDir) / (1 - const.player.moveDeadzone))
    end

    if self.controller.useAim then
        local worldAim = {camera.screenToWorld(self.controller.aimX.state, self.controller.aimY.state)}
        self.aimDir = vmath.normed(vmath.sub(worldAim, self.position))
    else
        self.aimDir = vmath.normed(self.moveDir)
    end

    self.time = self.time + const.SIM_DT
    self.frameCounter = self.frameCounter + 1

    self.invincibility = math.max(0, self.invincibility - const.SIM_DT)

    self.state:update()

    -- integratek
    self:move(vmath.mul(self.velocity, const.SIM_DT))

    self:updateCollisions()
end

function Player:updateCollisions()
    local collisions = GameObject.collider:collisions(self.shape)
    for other, mtv in pairs(collisions) do
        -- get new mtv after potentially having moved the shape in a collision before
        -- (this is a ghetto way of handling multiple simultaneous collisions)
        local collides, dx, dy = self.shape:collidesWith(other)
        local mtv = {dx, dy}
        if collides then
            if other._object.class == Polygon then
                if not self:onGround() then
                    print(utils.inspect(other._object.color), mtv[1], mtv[2])
                end
                self:move(mtv)
                local normal = mtv
                local velNormal, velTangent = vmath.split(self.velocity, normal)
                if vmath.dot(normal, velNormal) < 0.0 then -- velocity points into surface
                    self.velocity = velTangent
                end
                utils.callNonNil(self.state.collision, self.state, other, mtv)
            end
        end
    end
end

function Player:preHudDraw()
    utils.callNonNil(self.state.preHudDraw, self.state)
end

function Player:draw(dt)
    utils.callNonNil(self.state.preDraw, self.state)

    lg.setColor(100, 100, 100)

    if self.invincibility > 0 then
        lg.setColor(255, 255, 255)
    end

    lg.push()
        lg.translate(unpack(self.position))
        local w, h = const.player.width, const.player.height
        lg.rectangle("fill", -w/2, -h/2, w, h)
    lg.pop()

    utils.callNonNil(self.state.postDraw, self.state)
end

function Player:postHudDraw()
    utils.callNonNil(self.state.postHudDraw, self.state)

    lg.setColor(0, 255, 0)
    lg.setFont(fonts.big)
    lg.print(utils.inspect({
        position = self.position,
        velocity = self.velocity,
        onGround = self:onGround(),
    }), 5, 30)
    lg.print(self.state:tostring(), 5, 200)
end

return Player
