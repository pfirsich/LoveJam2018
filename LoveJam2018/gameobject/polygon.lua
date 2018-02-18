local utils = require("utils")
local class = require("libs.class")
local GameObject = require("gameobject")
local Hitbox = require("gameobject.player.hitbox")

Polygon = class("Polygon", GameObject)

function Polygon:initialize(points, color, solid, kunaiSolid, transparent, destructible, openable)
    GameObject.initialize(self)

    self.points = points
    self.color = color
    self.solid = solid
    self.kunaiSolid = kunaiSolid
    self.transparent = transparent
    self.destructible = destructible
    self.openable = openable

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
    self.mesh = lg.newMesh(vertices, "triangles", "static")

    if self.solid then
        self.shape = GameObject.collider:polygon(unpack(points))
        self.shape._object = self
    end

    self.hinted = false
end

function Polygon:update()
    if self.destructible then
        local collisions = Hitbox.collider:collisions(self.shape)
        for other, mtv in pairs(collisions) do
            self.markedForDeletion = true
        end
    end

    -- this only really works because the player is rendered (and update) last
    -- this is technically a hack
    self.hinted = false
end

function Polygon:hintInteract()
    if self.openable then
        self.hinted = true
    end
end

function Polygon:interact()
    if self.openable then
        self.solid = not self.solid
    end
end

function Polygon:destroy()
    if self.shape then
        GameObject.collider:remove(self.shape)
    end
end

function Polygon:draw()
    local color = {unpack(self.color)}
    color[4] = 255
    if self.openable and not self.solid then
        color[4] = 80
    end
    lg.setColor(color)
    lg.draw(self.mesh)

    if self.hinted then
        lg.setColor(255, 255, 100, color[4])
        lg.setLineWidth(6)
        lg.polygon("line", self.points)
        lg.setLineWidth(1)
    end
end

return Polygon
