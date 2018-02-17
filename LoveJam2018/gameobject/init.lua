local utils = require("utils")
local class = require("libs.class")
local HC = require("libs.HC")

local GameObject = class("GameObject")

function GameObject.resetWorld()
    GameObject.world = {}
    GameObject.idMap = {}
    GameObject.collider = HC.new(1)
end

function GameObject.getById(id)
    return GameObject.idMap[id]
end

local function gameObjectCmp(a, b)
    return a.depth < b.depth
end

function GameObject.updateAll()
    for _, object in ipairs(GameObject.world) do
        object:update()
    end
    table.sort(GameObject.world, gameObjectCmp)
end

function GameObject.drawAll(dt)
    for _, object in ipairs(GameObject.world) do
        object:draw(dt)
    end
end

function GameObject.callAll(name, ...)
    for _, object in ipairs(GameObject.world) do
        if object[name] then
            object[name](object, ...)
        end
    end
end

function GameObject:initialize()
    table.insert(GameObject.world, self)
    self.id = math.floor(lm.random(0, 2^52))
    GameObject.idMap[self.id] = self
    self.depth = 0
end

function GameObject:removeFromWorld()
    local index = nil
    for i, obj in ipairs(GameObject.world) do
        if obj == self then
            index = i
        end
    end
    table.remove(GameObject.world, index)
    GameObject.idMap[self.id] = nil
end

function GameObject:update()
end

function GameObject:draw()
end


return GameObject
