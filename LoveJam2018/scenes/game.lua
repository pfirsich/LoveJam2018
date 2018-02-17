local const = require("constants")
local utils = require("utils")
local GameObject = require("gameobject")
local controller = require("controller")
local fonts = require("media.fonts")
local map = require("map")
local camera = require("camera")
local Player = require("gameobject.player")

local scene = {name = "game"}

local mapData = nil
local player = nil

function scene.enter(mapName)
    lg.setBackgroundColor(20, 25, 100)

    GameObject.resetWorld()

    mapData = map.load(mapName)
    map.instance(mapData)

    local ctrl = controller.keyboard()
    local ctrl = controller.gamepad(love.joystick.getJoysticks()[1])
    local team = "defenders"
    local spawnZone = utils.table.randomChoice(mapData.spawnZones[team])
    player = Player(ctrl, team, utils.math.randInRect(unpack(spawnZone)))

    camera.bounds = mapData.bounds
end

function scene.tick()
    GameObject.updateAll()

    -- camera
    camera.target.position = player.position
    camera.approachTarget(const.cameraPosInterpFactor, const.cameraScaleInterpFactor)
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
