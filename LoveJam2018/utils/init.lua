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

for _, item in ipairs(lf.getDirectoryItems("utils")) do
    local path = "scenes/" .. item
    if item ~= "init.lua" then
        local name = item:sub(1,-5)
        utils[name] = require("utils." .. name)
    end
end

return utils
