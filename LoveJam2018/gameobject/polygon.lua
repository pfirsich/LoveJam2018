local const = require("constants")
local utils = require("utils")
local class = require("libs.class")
local GameObject = require("gameobject")
local Hitbox = require("gameobject.player.hitbox")
local audio = require("audio")
local net = require("net")

Polygon = class("Polygon", GameObject)
GameObject.classes.Polygon = Polygon

function Polygon.fromSerialization(serialized)
    assert(true, "Polygons should not be created dynamically")
end

function Polygon:initialize(points, color, solid, kunaiSolid, transparent, destructible, openable, climbable)
    GameObject.initialize(self)

    self.points = points
    self.color = color
    self.solid = solid
    self.kunaiSolid = kunaiSolid
    self.transparent = transparent
    self.destructible = destructible
    self.openable = openable
    self.climbable = climbable
    self.visible = true

    local triangles = lm.triangulate(points)
    local vertices = {}
    local textureScale = 0.1
    for t = 1, #triangles do
        for v = 1, 6, 2 do
            table.insert(vertices, {
                triangles[t][v+0],
                triangles[t][v+1],

                triangles[t][v+0] * textureScale,
                triangles[t][v+1] * textureScale,
            })
        end
    end
    self.triangles = triangles
    self.aabb = utils.math.getPolyAABB(self.points)
    self.center = {utils.math.polygonCentroid(self.points)}
    self.mesh = lg.newMesh(vertices, "triangles", "static")

    if self.solid then
        self.shape = GameObject.collider:polygon(unpack(points))
        self.shape._object = self
    end

    self.hinted = -100.0

    self.dynamic = self.openable or self.destructible
end

function Polygon:update()
    if self.destructible then
        local collisions = Hitbox.collider:collisions(self.shape)
        for other, mtv in pairs(collisions) do
            self.solid = false -- do this so the sound is already undampened
            audio.play("breakOpen", self.center)
            self.markedForDeletion = true
        end
    end
end

function Polygon:hintInteract()
    if self.openable then
        self.hinted = lt.getTime()
    end
end

function Polygon:interact()
    if self.openable then
        local solid = not self.solid
        -- set it to false, to audio.play doesn't detect occlusion by this polygon itself
        self.solid = false
        audio.play("open", self.center)
        self.solid = solid
    end
end

function Polygon:destroy()
    if self.shape then
        GameObject.collider:remove(self.shape)
    end
end

local serializedFields = {
    "solid",
}

function Polygon:serialize()
    return net.serializeFields(self, serializedFields)
end

function Polygon:deserialize(serialized)
    net.deserializeFields(self, serializedFields, serialized)
end

function Polygon:draw()
    local color = {unpack(self.color)}
    color[4] = 255
    if self.openable and not self.solid then
        color[4] = 80
    end
    lg.setColor(color)
    lg.draw(self.mesh)

    if lt.getTime() - self.hinted < const.hintDuration then
        lg.setColor(255, 255, 100, color[4])
        lg.setLineWidth(6)
        lg.polygon("line", self.points)
        lg.setLineWidth(1)
    end
end

return Polygon
