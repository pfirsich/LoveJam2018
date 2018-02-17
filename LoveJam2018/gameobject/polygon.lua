local utils = require("utils")
local class = require("libs.class")
local GameObject = require("gameobject")

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
    self.mesh = lg.newMesh(vertices, "triangles", "static")

    if self.solid then
        self.shape = GameObject.collider:polygon(unpack(points))
        self.shape._object = self
    end
end

function Polygon:update()

end

function Polygon:draw()
    lg.setColor(self.color)
    lg.draw(self.mesh)
end

return Polygon
