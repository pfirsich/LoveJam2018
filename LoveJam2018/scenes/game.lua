local GameObject = require("gameobject")
local controller = require("controller")
local fonts = require("media.fonts")
local map = require("map")
local camera = require("camera")

local scene = {name = "game"}

local mapData = nil

function scene.enter(mapName)
    lg.setBackgroundColor(20, 25, 100)

    GameObject.resetWorld()

    mapData = map.load(mapName)
    map.instance(mapData)

    camera.bounds = mapData.bounds
end

function scene.tick()
    GameObject.updateAll()

    -- camera
    camera.clampToBounds()
end

function scene.draw(dt)
    GameObject.callAll("preHudDraw")

    camera.push()
    GameObject.drawAll(dt)
    camera.pop()

    GameObject.callAll("postHudDraw")

    lg.setColor(100, 255, 100)
    lg.setFont(fonts.big)
    lg.print(love.timer.getFPS(), 5, 5)
end

return scene
