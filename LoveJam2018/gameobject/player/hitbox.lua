local const = require("constants")
local utils = require("utils")
local class = require("libs.class")
local HC = require("libs.HC")

local Hitbox = class("Hitbox")

Hitbox.collider = HC.new(const.colliderGridSize)

function Hitbox:initialize(owner, id, polygonPoints, hitData)
    self.owner = owner
    self.id = id
    self.centroid = {utils.math.polygonCentroid(polygonPoints)}
    self.shape = Hitbox.collider:polygon(unpack(polygonPoints))
    self.hitData = hitData
end

function Hitbox:transform(x, y, angle)
    local rCX, rCY = utils.math.rotatePoint(self.centroid[1], self.centroid[2], angle)
    self.shape:moveTo(x + rCX, y + rCY)
    self.shape:setRotation(angle)
end

function Hitbox:remove()
    Hitbox.collider:remove(self.shape)
end

return Hitbox
