lg = love.graphics
lf = love.filesystem
lm = love.math
lk = love.keyboard

require("libs.slam")
-- import this once before strict is imported, since HC doesn't like strict.lua
require("libs.HC")
require("libs.strict")

-- Import this once here and set flags
local msgpack = require("libs.MessagePack")
msgpack.set_number("float")
msgpack.set_string("string")

local scenes = require("scenes")
local utils = require("utils")
local const = require("constants")
local audio = require("audio")
local fonts = require("media.fonts")
local config = require("config")
local console = require("libs.console")
local clientCommands = require("consolecommands-client")

function love.load(args)
    scenes.require()
    const.reload()
    audio.load()
    config.load()

    -- load scenes
    for name, scene in pairs(scenes) do
        scene.realTime = 0
        scene.simTime = 0
        scene.frameCounter = 0
        utils.callNonNil(scene.load)
    end

    scenes.enter(scenes.game, "firsttest")
end

function love.update(dt)
    console.update(dt)
end

function love.draw(dt)
    scenes.current.draw(dt)
    lg.setFont(fonts.console)
    console.draw()
    lg.setFont(fonts.default)
end

function love.keypressed(key)
    console.keypressed(key)

    local ctrl = lk.isDown("lctrl") or lk.isDown("rctrl")
    if ctrl and key == "r" then
        const.reload()
    end
    if key == "f11" then
        utils.toggleFullscreen()
    end
end

function love.textinput(text)
    console.textinput(text)
end

function love.resize(width, height)
    if scenes.current.resize then
        scenes.current.resize(width, height)
    end
end

function love.run()
    if love.math then
        love.math.setRandomSeed(os.time())
    end

    if love.load then love.load(arg) end

    -- We don't want the first frame's dt to include time taken by love.load.
    if love.timer then love.timer.step() end

    local dt = 0

    -- Main loop time.
    while true do
        -- Process events.
        local scene = scenes.current
        while scene.simTime <= scene.realTime do
            scene.simTime = scene.simTime + const.SIM_DT
            scene.frameCounter = scene.frameCounter + 1

            if love.event then
                love.event.pump()
                for name, a,b,c,d,e,f in love.event.poll() do
                    if name == "quit" then
                        if not love.quit or not love.quit() then
                            utils.callNonNil(scene.exit)
                            return a
                        end
                    end

                    love.handlers[name](a, b, c, d, e, f)
                    utils.callNonNil(scene[name], a, b, c, d, e, f)
                end
            end

            love.update(const.SIM_DT)
            utils.callNonNil(scene.tick)
        end

        if love.timer then
            love.timer.step()
            dt = love.timer.getDelta()
        end

        scene.realTime = scene.realTime + dt / const.slowMo

        if lg and lg.isActive() then
            lg.clear(lg.getBackgroundColor())
            lg.origin()
            love.draw(dt)
            lg.present()
        end

        if love.timer then love.timer.sleep(0.001) end
    end
end
