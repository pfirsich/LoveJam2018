local utils = {}

utils.inspect = require("libs.inspect")
utils.class = require("libs.class")

function utils.callNonNil(f, ...)
    if f then f(...) end
end

function utils.loveDoFile(path)
    local chunk, err = love.filesystem.load(path)
    if chunk then
        return chunk()
    else
        error(err)
    end
end

function utils.nop()
    -- pass
end

function utils.ModifiedChecker()
    local lastModified = {}

    return function(path)
        local mod = lf.getLastModified(path)
        return not lastModified[path] or lastModified[path] < mod
    end
end

function utils.toggleFullscreen()
    local w, h, flags = love.window.getMode()
    if flags.fullscreen then
        conf = {window = {}, modules={}}
        love.conf(conf)

        flags = {
            resizable = conf.window.resizable,
            vsync = conf.window.vsync,
        }

        love.window.setMode(conf.window.width, conf.window.height, flags)
    else
        utils.autoFullscreen()
    end
end

function utils.autoFullscreen()
    local supported = love.window.getFullscreenModes()
    table.sort(supported, function(a, b) return a.width*a.height < b.width*b.height end)

    local filtered = {}
    local scrWidth, scrHeight = love.window.getDesktopDimensions()
    for _, mode in ipairs(supported) do
        if mode.width*scrHeight == scrWidth*mode.height then
            table.insert(filtered, mode)
        end
    end
    supported = filtered

    local max = supported[#supported]
    local flags = {fullscreen = true}
    if not love.window.setMode(max.width, max.height, flags) then
        error(string.format("Resolution %dx%d could not be set successfully.", max.width, max.height))
    end
    if love.resize then love.resize(max.width, max.height) end
end

for _, item in ipairs(lf.getDirectoryItems("utils")) do
    local path = "scenes/" .. item
    if item ~= "init.lua" then
        local name = item:sub(1,-5)
        utils[name] = require("utils." .. name)
    end
end

return utils
