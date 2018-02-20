local const = require("constants")
local utils = require("utils")
local vmath = require("utils.vmath")
local GameObject = require("gameobject")
local controller = require("controller")
local fonts = require("media.fonts")
local map = require("map")
local camera = require("camera")
local Player = require("gameobject.player")
local Polygon = require("gameobject.polygon")
local audio = require("audio")
local client = require("net.client")
local console = require("libs.console")

local scene = {name = "game"}

scene.player = nil
scene.mapData = nil

local shadowMesh = lg.newMesh(2048, "triangles", "dynamic")
local shadowCanvas = lg.newCanvas()
local enemyCanvas = lg.newCanvas()
local background = lg.newImage("media/bg.png")
local messageFeed = {}
local maxFeedMessages = 15

function scene.enter(mapName)
    lg.setBackgroundColor(20, 25, 100)
    love.window.maximize()

    if mapName then
        scene.loadMap(mapName)
    end
end

function scene.loadMap(mapName)
    scene.mapData = map.load(mapName)
    map.instance(scene.mapData)
    scene.player = nil
end

local function getSpawnPoint(team)
    local spawnZone = utils.table.randomChoice(scene.mapData.spawnZones[team])
    return utils.math.randInRect(unpack(spawnZone))
end

function scene.respawn()
    local player = scene.player
    if player then
        player.team = player.nextTeam or player.team
        player.nextTeam = nil
        player.position = vmath.copy(getSpawnPoint(player.team))
    end
end

function scene.joinTeam(team)
    if not scene.player then
        if team == "attackers" or team == "defenders" then
            scene.player = Player(team, getSpawnPoint(team))
            scene.player.owned = true
            scene.setController(love.joystick.getJoysticks()[1])
        end
    else
        if team == "spectator" then
            scene.player:removeFromWorld()
            scene.player = nil
        else
            scene.player.nextTeam = team
        end
    end
end

function scene.setController(joystick)
    if scene.player then
        if joystick then
            scene.player.controller = controller.gamepad(joystick)
        else
            scene.player.controller = controller.keyboard()
        end
    end
end

function scene.resize(width, height)
    shadowCanvas = lg.newCanvas()
    enemyCanvas = lg.newCanvas()
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
                extrudePoly(vertices, object.points, scene.player.position)
            end
        end
    end
    shadowMesh:setVertices(vertices)
    -- check if range > 0
    shadowMesh:setDrawRange(1, #vertices)
end

function scene.tick()
    client.update()

    -- camera
    if scene.player then
        camera.target.position = scene.player.position
        camera.approachTarget(const.cameraPosInterpFactor, const.cameraScaleInterpFactor)
        camera.bounds = scene.mapData.bounds
        camera.clampToBounds()
        audio.listener = scene.player.position
    else
        local x, y, w, h = unpack(scene.mapData.bounds)
        camera.position = {x + w/2, y + h/2}
        local winW, winH = lg.getDimensions()
        local scaleX, scaleY = winW / w, winH / h
        camera.scale = math.min(scaleX, scaleY)
    end

    if scene.player then
        updateShadowMesh()
    end
end

function scene.postMessage(msg, lvl)
    table.insert(messageFeed, 1, {msg = msg, lvl = lvl, time = lt.getTime()})
    if #messageFeed > maxFeedMessages then
        table.remove(messageFeed)
    end
end

local function drawMessageFeed()
    local winW, winH = lg.getDimensions()
    local font = lg.getFont()

    local maxWidth = 0
    for i = #messageFeed, 1, -1 do
        if lt.getTime() - messageFeed[i].time > const.messageDuration then
            table.remove(messageFeed, i)
        else
            maxWidth = math.max(maxWidth, font:getWidth(messageFeed[i].msg))
        end
    end

    local margin = 10
    local y = winH - margin
    lg.setColor(const.messageFeedBgColor)
    local h = font:getHeight() * #messageFeed + margin*2
    lg.rectangle("fill", margin, y - h, maxWidth + margin*2, h)
    y = y - margin
    for _, msg in ipairs(messageFeed) do
        y = y - font:getHeight()
        lg.setColor(const.messageLevelColors[msg.lvl or "other"])
        lg.print(msg.msg, margin*2, y)
    end
end

local enemyShader = lg.newShader([[
extern sampler2D shadowTexture;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
    vec4 texturecolor = Texel(texture, texture_coords);
    float shadow = Texel(shadowTexture, texture_coords).a;
    return texturecolor * (1.0 - shadow);
}
]])

function scene.draw(dt)
    local winW, winH = lg.getDimensions()

    GameObject.callAll("preHudDraw")

    lg.draw(background, 0, 0, 0, winW / background:getWidth(), winH / background:getHeight())

    camera.push()
        for _, object in ipairs(GameObject.world) do
            if scene.player == nil or object.class ~= Player or
               (object ~= scene.player and scene.player.team == object.team) then
                object:draw(dt)
            end
        end
    camera.pop()

    if scene.player then
        camera.push()
            lg.setCanvas(enemyCanvas)
            lg.clear(0, 0, 0, 0)
            for _, object in ipairs(GameObject.world) do
                if object.class == Player and scene.player.team ~= object.team then
                    object:draw(dt)
                end
            end
            lg.setCanvas()

            lg.setCanvas(shadowCanvas)
            lg.clear(0, 0, 0, 0)
            lg.setColor(0, 0, 0, 255)
            lg.draw(shadowMesh)
            lg.setCanvas()
        camera.pop()

        lg.setShader(enemyShader)
        enemyShader:send("shadowTexture", shadowCanvas)
        lg.draw(enemyCanvas)
        lg.setShader()

        lg.setColor(0, 0, 0, 120)
        lg.draw(shadowCanvas)
    end

    camera.push()
        if scene.player then
            scene.player:draw(dt)
        else
            lg.setColor(255, 0, 0, 255)
            lg.circle("fill", audio.listener[1], audio.listener[2], 20)
        end
    camera.pop()

    lg.setColor(255, 255, 255, 255)
    GameObject.callAll("postHudDraw")

    lg.setFont(fonts.huge)
    drawMessageFeed()

    lg.setColor(100, 255, 100)
    lg.setFont(fonts.big)
    lg.print(love.timer.getFPS(), 5, 5)
end

function scene.mousepressed(x, y, button)
    if button == 1 and not scene.player then
        audio.listener = {camera.screenToWorld(x, y)}
    end
end

function scene.keypressed(key)

end

return scene
