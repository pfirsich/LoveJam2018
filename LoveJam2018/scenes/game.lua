local GameObject = require("gameobject")
local controller = require("controller")

local scene = {name = "game"}

function scene.enter(mapFileName, _client)
    GameObject.resetWorld()

    local ctrl = controller.gamepad(love.joystick.getJoysticks()[1])
    local ctrl = controller.keyboard()
end

function scene.tick()
    GameObject.updateAll()
end

function scene.draw(dt)
    GameObject.callAll("preHudDraw")

    GameObject.drawAll(dt)

    GameObject.callAll("postHudDraw")
end

return scene
