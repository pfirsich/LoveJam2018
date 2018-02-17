local states = require("gameobject.player.states.states")

states.Base = require("gameobject.player.states.base")

local root = "gameobject/player/states"
for _, file in ipairs(lf.getDirectoryItems(root)) do
    if lf.isFile(root .. "/" .. file) and file:sub(-4) == ".lua" and
            file ~= "init.lua" and file ~= "states.lua" then
        local state = require ("gameobject.player.states." .. file:sub(1, -5))
        states[state.name] = state
    end
end

return states
