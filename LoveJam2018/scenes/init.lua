local utils = require("utils")

local mod = {}
-- I do it this way, so you can iterate over the k,v pairs in scenes
-- I think having `current`, `require` and `enter` inside `scenes` (even only via the metatable)
-- is bad design, but I am not sure how to make it better
local scenes = setmetatable({}, {__index = mod})
scenes.empty = {load = utils.nop, draw = utils.nop}

mod.current = scenes.empty

function mod.enter(scene, ...)
    if mod.current and mod.current.exit then
        mod.current.exit(scene)
    end

    mod.current = scene
    if mod.current.enter then
        mod.current.enter(...)
    end
end

function mod.require()
    for _, item in ipairs(lf.getDirectoryItems("scenes")) do
        local path = "scenes/" .. item

        local reqPath = nil

        if lf.isFile(path) and item ~= "init.lua" then
            reqPath = "scenes." .. item:sub(1, -5)
        elseif lf.isDirectory(path) then
            reqPath = "scenes." .. item
        end

        if reqPath then
            local scene = require(reqPath)
            assert(scene.name ~= "current" and scene.name ~= "enter" and scene.name ~= "require")
            scenes[scene.name] = scene
        end
    end
end

return scenes
