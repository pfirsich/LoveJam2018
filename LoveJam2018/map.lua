local utils = require("utils")
local GameObject = require("gameobject")
local Polygon = require("gameobject.polygon")
local console = require("libs.console")

local map = {}

local parseEntity = {}

local function getComponent(entity, id)
    for _, comp in ipairs(entity.components) do
        if comp.id == id then
            return comp
        end
    end
end

local function getAABB(points)
    local minX, maxX = math.huge, -math.huge
    local minY, maxY = math.huge, -math.huge
    for i = 1, #points, 2 do
        minX = math.min(minX, points[i+0])
        maxX = math.max(maxX, points[i+0])

        minY = math.min(minY, points[i+1])
        maxY = math.max(maxY, points[i+1])
    end
    return {minX, minY, maxX - minX, maxY - minY}
end

local function getEntityAABB(entity)
    local poly = getComponent(entity, "polygon")
    local aabb = getAABB(poly.points)

    local trafo = getComponent(entity, "transforms")
    local position = trafo.position

    aabb[1] = aabb[1] + position[1]
    aabb[2] = aabb[2] + position[2]

    return aabb
end

local function transformPoly(points, transforms)
    local ret = {}
    for i = 1, #points, 2 do
        -- TODO: add rotation and scale
        ret[i+0] = points[i+0] + transforms.position[1]
        ret[i+1] = points[i+1] + transforms.position[2]
    end
    return ret
end

function parseEntity.levelbounds(mapData, entity)
    mapData.bounds = getEntityAABB(entity)
end

function parseEntity.spawnzone(mapData, entity)
    local teamComponent = getComponent(entity, "team")
    local team = teamComponent.value and "defenders" or "attackers"
    mapData.spawnZones = mapData.spawnZones or {}
    mapData.spawnZones[team] = mapData.spawnZones[team] or {}

    table.insert(mapData.spawnZones[team], getEntityAABB(entity))
end

function parseEntity.polygon(mapData, entity)
    local polyComponent = getComponent(entity, "polygon")
    local polygon = {
        points = transformPoly(polyComponent.points, getComponent(entity, "transforms")),
        color = polyComponent.color,
        solid = getComponent(entity, "solid").value,
        kunaiSolid = getComponent(entity, "kunaiSolid").value,
        transparent = getComponent(entity, "transparent").value,
        destructible = getComponent(entity, "destructible").value,
        openable = getComponent(entity, "openable").value,
        climbable = true,
    }
    mapData.polygons = mapData.polygons or {}
    table.insert(mapData.polygons, polygon)
end

function map.load(name)
    local fileData = utils.loveDoFile("media/maps/" .. name .. ".map")
    local mapData = {}
    mapData.name = name
    for _, entity in ipairs(fileData.entities) do
        if parseEntity[entity.type] then
            parseEntity[entity.type](mapData, entity)
        else
            print(("Ignored entity of type '%s'"):format(entity.type))
        end
    end
    assert(mapData.bounds, "Need bounds object")
    assert(mapData.spawnZones.defenders and mapData.spawnZones.attackers, "Need spawns for both teams")
    return mapData
end

local function rectanglePolygon(x, y, w, h)
    return {x,y,  x+w,y,  x+w,y+h,  x,y+h}
end

function map.instance(mapData)
    console.print(("Instantiating map '%s'"):format(mapData.name))

    GameObject.resetWorld()
    local idCounter = utils.counter()

    for _, polygon in ipairs(mapData.polygons) do
        local poly = Polygon(utils.table.unpackKeys(polygon,
            {"points", "color", "solid", "kunaiSolid", "transparent",
            "destructible", "openable", "climbable"}))
        poly:changeId(idCounter:get())
    end

    -- level bounds
    local x, y, w, h = unpack(mapData.bounds)
    local boundW = 200
    local params = {{100, 100, 100, 255}, true, false, false, false, false, false}
    local coords = {
        {x-boundW, y,        boundW, h},
        {x+w,      y,        boundW, h},
        {x,        y-boundW, w,      boundW},
        {x,        y+h,      w,      boundW},
    }
    for _, coord in ipairs(coords) do
        local poly = Polygon(rectanglePolygon(unpack(coord)), unpack(params))
        poly:changeId(idCounter:get())
        poly.visible = false
    end
end

return map
