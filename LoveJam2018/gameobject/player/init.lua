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
local animation = require("animation")
local controller = require("controller")
local net = require("net")

local Player = class("Player", GameObject)
GameObject.classes.Player = Player

local sheetFrameSize = 512
local ninjaSheet = love.graphics.newImage("media/images/ninja.png")
local animFrames = animation.getFrames(ninjaSheet, sheetFrameSize, sheetFrameSize)

local playerAnimations = nil
-- we can't do it here right away, since const is not already loaded
local function loadPlayerAnimations()
    playerAnimations = {}
    for name, frames in pairs(const.player.animationFrames) do
        playerAnimations[name] = animation.Animation(1.0)
        playerAnimations[name]:addFrames(animation.sliceFrames(animFrames, unpack(frames)))
    end
end

function Player:initialize(team, position)
    GameObject.initialize(self)
    self.depth = 1
    self.controller = controller.dummy()
    self.team = team
    self.nextTeam = nil
    self.position = vmath.copy(position)
    self.velocity = {0, 0}

    local w, h = const.player.width, const.player.height
    --self.shape = GameObject.collider:rectangle(0, 0, w, h)
    self.shape = GameObject.collider:polygon(0,-h/2,  -w/2,0,  0,h/2,  w/2,0)
    self.shape._object = self
    self.frameCounter = 0
    self.time = 0
    self.canDash = true
    self.invincibility = 0
    self.flipped = false

    local w, h = const.player.width * const.player.groundProbeWidthFactor * 0.05, const.player.groundProbeHeight
    self._groundProbe = HCshapes.newPolygonShape(0, 0,  w, 0,  w, h,  0, h)

    local w, h = const.player.interactDistance, const.player.height * const.player.interactHeightFactor
    self._interactProbe = HCshapes.newPolygonShape(0, 0,  w, 0,  w, h,  0, h)

    self._hitboxIdCounter = 0

    if not playerAnimations then
        loadPlayerAnimations()
    end
    self.animation = animation.AnimationState()
    for name, anim in pairs(playerAnimations) do
        self.animation:addAnimation(name, anim)
    end

    self:setState(states.Wait)

    self.dynamic = true
end

local serializedFields = {
    "team",
    "position",
    "velocity",
    "time",
    "invincibility",
    "flipped",
    "_animation",
    "_state",
}

function Player.fromSerialization(serialized)
    local team = net.getSerializedField(serializedFields, serialized, "team")
    local position = net.getSerializedField(serializedFields, serialized, "position")
    local player = Player(team, position)
    return player
end

function Player:serialize()
    self._animation = {self.animation.current, self.animation.time}
    self._state = self.state:serialize()
    return net.serializeFields(self, serializedFields)
end

function Player:deserialize(serialized)
    net.deserializeFields(self, serializedFields, serialized)
    self.animation.current = self._animation[1]
    self.animation.time = self._animation[2]
    self.state:deserialize(self._state)
end

function Player:setState(stateClass, ...)
    local state = stateClass(self)
    if self.state then
        self.state:exit(state)
    end
    self.state = state
    self.state:enter(...)
end

function Player:getNextHitboxId()
    self._hitboxIdCounter = self._hitboxIdCounter + 1
    return self._hitboxIdCounter
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

Player.interactRpc = net.Rpc(function(id)
    local obj = GameObject.getById(id)
    if obj and obj.owned and obj.interact then
        obj:interact()
    end
end)

function Player:interact()
    local dir = self.flipped and {-1, 0} or {1, 0}
    local offset = const.player.width/2 + const.player.interactDistance/2
    self._interactProbe:moveTo(unpack(vmath.add(self.position, vmath.mul(dir, offset))))
    local collisions = GameObject.collider:collisions(self._interactProbe)
    for other, mtv in pairs(collisions) do
        local obj = other._object
        if obj.hintInteract then
            obj:hintInteract()
            if self.controller.use.pressed then
                Player.interactRpc(obj.id)
            end
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
        if other._object.class == Polygon and other._object.solid then
            return true
        end
    end
    return false
end

function Player:updateFlipped(dir)
    dir = dir or self.moveDir
    if dir[1] > 0 then
        self.flipped = false
    elseif dir[1] < 0 then
        self.flipped = true
    end
end

function Player:destroy()
    self.state:exit(states.Base(self))
    GameObject.collider:remove(self.shape)
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
            if other._object.class == Polygon and other._object.solid then
                self:move(mtv)
                local preCollisionVelocity = vmath.copy(self.velocity)
                local normal = mtv
                local velNormal, velTangent = vmath.split(self.velocity, normal)
                if vmath.dot(normal, velNormal) < 0.0 then -- velocity points into surface
                    self.velocity = velTangent
                end
                utils.callNonNil(self.state.collision, self.state, other, mtv, preCollisionVelocity)
            end
        end
    end
end

function Player:preHudDraw()
    utils.callNonNil(self.state.preHudDraw, self.state)
end

function Player:draw(dt)
    utils.callNonNil(self.state.preDraw, self.state)

    self.animation:update(dt)
    local animDur = const.player.animationDurations[self.animation.current]
    if animDur then
        self.animation.animations[self.animation.current].duration = animDur
    end

    lg.setColor(const.player.teamColors[self.team])

    if self.invincibility > 0 then
        lg.setColor(255, 255, 255)
    end

    lg.push()
        lg.translate(unpack(self.position))
        local w, h = const.player.width, const.player.height
        --lg.rectangle("fill", -w/2, -h/2, w, h)
        local scale = const.player.animationScale
        lg.scale(scale)
        lg.scale(self.flipped and -1 or 1, 1)
        self.animation:draw(-sheetFrameSize/2, h/2/scale - sheetFrameSize)
    lg.pop()

    utils.callNonNil(self.state.postDraw, self.state)
end

function Player:postHudDraw()
    utils.callNonNil(self.state.postHudDraw, self.state)

--[[    lg.setColor(0, 255, 0)
    lg.setFont(fonts.small)
    lg.print(utils.inspect({
        position = self.position,
        velocity = self.velocity,
        onGround = self:onGround(),
        animation = self.animation.current,
    }), 5, 35)
    lg.print(self.state:tostring(), 5, 150)--]]
end

return Player
