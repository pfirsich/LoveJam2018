local const = require("constants")
local class = require("libs.class")
local states = require("gameobject.player.states.states")
local vmath = require("utils.vmath")
local Hitbox = require("gameobject.player.hitbox")

local Attack = class("Attack", states.Base)

function Attack:initialize(player, ...)
    states.Base.initialize(self, player)
end

local dirVec ={
    left = {-1, 0},
    right = {1, 0},
    up = {0, -1},
    down = {0, 1},
}

local dirClass = {
    left = "side",
    right = "side",
    up = "up",
    down = "down",
}

function Attack:enter()
    local player = self.player

    local dir = vmath.copy(player.moveDir)
    if vmath.len(dir) < 1e-5 then
        self.dir = player.flipped and "left" or "right"
    else
        local dirName = "neutral"
        if math.abs(dir[1]) > math.abs(dir[2]) then
            if dir[1] > 0 then
                dirName = "right"
            else
                dirName = "left"
            end
        else
            if dir[2] > 0 then
                dirName = "down"
            else
                dirName = "up"
            end
        end
        self.dir = dirName
    end
    self.startup = const.player.attackStartup
    self.active = const.player.attackActive
    self.cooldown = const.player.attackCooldown

    player:updateFlipped()
    player.velocity = vmath.add(player.velocity,
        vmath.mul(dirVec[self.dir], const.player.attackImpulse[dirClass[self.dir]]))
end

function Attack:exit(newState)
    if self.hitbox then
        self.hitbox:remove()
        self.hitbox = nil
    end
end

local hitboxAngle = {
    right = 0,
    left = math.pi,
    up = -math.pi/2,
    down = math.pi/2,
}

function Attack:updateHitbox()
    local player = self.player
    if self:state() == "active" then
        if not self.hitbox then
            self.hitbox = Hitbox(player.id, player:getNextHitboxId(),
                const.player.attackHitbox, {})
        end
        self.hitbox:transform(player.position[1], player.position[2], hitboxAngle[self.dir])
    else
        if self.hitbox then
            self.hitbox:remove()
            self.hitbox = nil
        end
    end
end

function Attack:state()
    local dt = self.player.time - self.start
    if dt < self.startup then
        return "startup"
    elseif dt < self.startup + self.active then
        return "active"
    elseif dt < self.startup + self.active + self.cooldown then
        return "cooldown"
    end
end

function Attack:isActive()
    local dt = player.time - self.start - const.player.startup
    return dt > 0 and dt < self.active
end

function Attack:update()
    local player = self.player

    player:friction(const.player.waitFriction)

    local maxFallSpeed = const.player.maxFallSpeed
    local gravity = const.player.maxFallSpeed / const.player.fallAccelDur

    if player.velocity[2] < maxFallSpeed then
        player.velocity[2] = player.velocity[2] + gravity * const.SIM_DT
    end

    self:updateHitbox()

    if player.time - self.start > self.startup + self.active + self.cooldown then
        player:setState(states.Fall)
    end
end

local function attackArcMesh(innerXRad, innerYRad, outerXRad, outerYRad, angleRange, samples)
    samples = samples or 25
    angleRange = math.pi * 0.5
    local points = {}
    for side = 0, 1 do
        local xRad = side < 0.5 and innerXRad or outerXRad
        local yRad = side < 0.5 and innerYRad or outerYRad
        for i = 1, samples do
            local angle = -angleRange + 2*angleRange/(samples-1)*(i-1)
            if side < 0.5 then angle = -angle end
            table.insert(points, xRad * math.cos(angle))
            table.insert(points, yRad * math.sin(angle))
        end
    end

    local vertices = {}
    local triangles = lm.triangulate(points)
    for _, tri in ipairs(triangles) do
        for i = 1, 6, 2 do
            table.insert(vertices, {tri[i+0], tri[i+1]})
        end
    end

    return lg.newMesh(vertices, "triangles", "static")
end

local poly = attackArcMesh(150, 100, 200, 100)

local angleOffset = {
    left = 0,
    right = 0,
    up = -math.pi/2,
    down = math.pi/2,
}

function Attack:postDraw()
    local player = self.player
    if player.time - self.start < self.startup + self.active then
        lg.setColor(255, 255, 255, 255)
        lg.push()
            lg.translate(unpack(player.position))
            lg.scale(player.flipped and -1 or 1, 1)

            lg.stencil(function()
                local fromAngle = angleOffset[self.dir] - math.pi/2
                local t = math.min(1.0, (player.time - self.start) / (self.startup + self.active))
                local toAngle = fromAngle + math.pi * t
                lg.arc("fill", 0, 0, 300, fromAngle, toAngle, 20)
            end)

            lg.setStencilTest("greater", 0)
            lg.rotate(angleOffset[self.dir])
            lg.draw(poly)
            lg.setStencilTest()
        lg.pop()
    end

--[[    if self.hitbox then
        lg.setColor(255, 0, 0, 100)
        self.hitbox.shape:draw()
    end--]]
end

return Attack
