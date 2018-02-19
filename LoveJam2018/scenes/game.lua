local const = require("constants")
local utils = require("utils")
local GameObject = require("gameobject")
local controller = require("controller")
local fonts = require("media.fonts")
local map = require("map")
local camera = require("camera")
local Player = require("gameobject.player")
local Polygon = require("gameobject.polygon")
local audio = require("audio")

local scene = {name = "game"}

local mapData = nil
local player = nil
local shadowMesh = nil
local shadowCanvas = nil
local background = lg.newImage("media/bg.png")

function scene.enter(mapName)
    lg.setBackgroundColor(20, 25, 100)

    GameObject.resetWorld()

    mapData = map.load(mapName)
    map.instance(mapData)

    local joystick = love.joystick.getJoysticks()[1]
    local ctrl = controller.keyboard()
    if joystick and true then
        ctrl = controller.gamepad(joystick)
    end
    local team = "defenders"
    local spawnZone = utils.table.randomChoice(mapData.spawnZones[team])
    player = Player(ctrl, team, utils.math.randInRect(unpack(spawnZone)))

    camera.bounds = mapData.bounds

    shadowMesh = lg.newMesh(2048, "triangles", "dynamic")
    shadowCanvas = lg.newCanvas()
end

function scene.resize(width, height)
    shadowCanvas = lg.newCanvas()
end

local function rel(x, y, fromx, fromy)
    local relX, relY = x - fromx, y - fromy
    local len = math.sqrt(relX*relX + relY*relY)
    return relX / len, relY / len
end

local function extrudePoint(x, y, from, distance)
    distance = distance or 5000
    local relX, relY = rel(x, y, from[1], from[2])
    return from[1] + relX * distance, from[2] + relY * distance
end

local function extrudeEdge(vertices, x1,y1,x2,y2, from)
    -- f stands for "far" (i.e. extruded)
    local fx1, fy1 = extrudePoint(x1, y1, from)
    local fx2, fy2 = extrudePoint(x2, y2, from)

    table.insert(vertices, {x1, y1})
    table.insert(vertices, {x2, y2})
    table.insert(vertices, {fx1, fy1})

    table.insert(vertices, {x2, y2})
    table.insert(vertices, {fx2, fy2})
    table.insert(vertices, {fx1, fy1})
end

local function extrudePoly(vertices, poly, from)
    for i = 1, #poly, 2 do
        local nexti = i + 2
        if nexti > #poly then
            nexti = 1
        end
        local x1, y1 = poly[i+0], poly[i+1]
        local x2, y2 = poly[nexti+0], poly[nexti+1]

        local tangentX, tangentY = rel(x2, y2, x1, y1)
        local normalX, normalY = tangentY, -tangentX

        -- is one enough?
        local rel1X, rel1Y = rel(x1, y1, from[1], from[2])
        if rel1X*normalX + rel1Y*normalY > 0 then
            extrudeEdge(vertices, x1, y1, x2, y2, from)
        end
    end
end

local function updateShadowMesh()
    local camRect = {camera.getAABB()}

    local vertices = {}
    for _, object in ipairs(GameObject.world) do
        if object.class == Polygon and object.solid and not object.transparent then
            -- we can't just check if every point is in the rect, since we might miss some intersections
            if utils.math.rectIntersect(object.aabb, camRect) then
                extrudePoly(vertices, object.points, player.position)
            end
        end
    end
    shadowMesh:setVertices(vertices)
    -- check if range > 0
    shadowMesh:setDrawRange(1, #vertices)
end

function scene.tick()
    GameObject.updateAll()
    GameObject.removeMarked()

    -- camera
    camera.target.position = player.position
    camera.approachTarget(const.cameraPosInterpFactor, const.cameraScaleInterpFactor)
    camera.clampToBounds()

    updateShadowMesh()
end

function scene.draw(dt)
    local winW, winH = lg.getDimensions()

    GameObject.callAll("preHudDraw")

    lg.draw(background, 0, 0, 0, winW / background:getWidth(), winH / background:getHeight())

    camera.push()
        for _, object in ipairs(GameObject.world) do
            if object ~= player then
                object:draw(dt)
            end
        end

        lg.setCanvas(shadowCanvas)
        lg.clear(0, 0, 0, 0)
        lg.setColor(0, 0, 0, 255)
        lg.draw(shadowMesh)
        lg.setCanvas()
    camera.pop()
    lg.setColor(0, 0, 0, 120)
    lg.draw(shadowCanvas)

    camera.push()
        player:draw(dt)

        lg.setColor(255, 0, 0, 255)
        lg.circle("fill", audio.listener[1], audio.listener[2], 20)
    camera.pop()

    lg.setColor(255, 255, 255, 255)
    GameObject.callAll("postHudDraw")

    lg.setColor(100, 255, 100)
    lg.setFont(fonts.big)
    lg.print(love.timer.getFPS(), 5, 5)
end

function scene.mousepressed(x, y, button)
    if button == 1 then
        audio.listener = {camera.screenToWorld(x, y)}
    end
end

return scene
