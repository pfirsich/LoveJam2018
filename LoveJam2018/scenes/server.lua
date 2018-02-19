local const = require("constants")
local console = require("libs.console")
local clientCommands = require("consolecommands-client")
local server = require("net.server")

local scene = {name = "server"}

function scene.load()

end

function scene.enter(port)
    port = tonumber(port)
    assert(port, "Port must be a number")
    server.start(port)
end

function scene.exit()

end

function scene.tick()
    server.update()
end

function scene.draw()

end

function scene.keypressed(key)

end

return scene
