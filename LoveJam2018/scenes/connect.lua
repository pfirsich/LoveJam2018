local console = require("libs.console")

local const = require("constants")
local clientCommands = require("consolecommands-client")
local client = require("net.client")
local scenes = require("scenes")

local scene = {name = "connect"}

function scene.load()

end

function scene.enter(addr)
    if not addr:find(":") then
        if addr:len() == 0 then
            addr = "localhost:" .. const.net.defaultPort
        else
            addr = addr .. ":" .. const.net.defaultPort
        end
    end
    client.connect(addr)
    clientCommands.showProgress(("Connecting to %s..."):format(addr))
end

function scene.exit()
    -- "connection to.." is replaced by join team thing!
end

function scene.tick()
    client.update()
    if client.connected then
        scenes.enter(scenes.game)
    end
end

function scene.draw()

end

return scene
