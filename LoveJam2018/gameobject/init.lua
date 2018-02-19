local const = require("constants")
local utils = require("utils")
local class = require("libs.class")
local HC = require("libs.HC")

local GameObject = class("GameObject")

GameObject.classes = {}

GameObject.world = {}
GameObject.idMap = {}
GameObject.collider = HC.new(const.colliderGridSize)

function GameObject.resetWorld()
    GameObject.world = {}
    GameObject.idMap = {}
    GameObject.collider = HC.new(const.colliderGridSize)
end

function GameObject.getById(id)
    return GameObject.idMap[id]
end

local function gameObjectCmp(a, b)
    return a.depth < b.depth
end

function GameObject.depthSort()
    utils.table.stableSort(GameObject.world, gameObjectCmp)
end

function GameObject.callAll(name, ...)
    for _, object in ipairs(GameObject.world) do
        if object[name] then
            object[name](object, ...)
        end
    end
end

function GameObject.removeMarked()
    for i = #GameObject.world, 1, -1 do
        if GameObject.world[i].markedForDeletion then
            GameObject.world[i]:removeFromWorld()
        end
    end
end

function GameObject:initialize()
    table.insert(GameObject.world, self)
    repeat
        self.id = math.floor(lm.random(0, 2^52))
    until GameObject.idMap[self.id] == nil
    GameObject.idMap[self.id] = self
    self.depth = 0
    self.markedForDeletion = false
    self.owned = false
end

function GameObject:changeId(newId)
    GameObject.idMap[self.id] = nil
    self.id = newId
    GameObject.idMap[self.id] = self
end

function GameObject:removeFromWorld()
    local object, index = nil, nil
    for i, obj in ipairs(GameObject.world) do
        if obj == self then
            object = obj
            index = i
        end
    end
    object:destroy()
    table.remove(GameObject.world, index)
    GameObject.idMap[self.id] = nil
end

function GameObject:destroy()
end

function GameObject:update()
end

function GameObject:draw()
end


return GameObject
