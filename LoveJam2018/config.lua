local msgpack = require("libs.MessagePack")

local values = {}
local config = setmetatable({}, {__index = values})

function config.load()
    if lf.isFile("config") then
        local read = msgpack.unpack(lf.read("config"))
        for k, v in pairs(read) do
            values[k] = v
        end
    end
end

function config.write()
    lf.write("config", msgpack.pack(values))
end

function config.set(name, value)
    values[name] = value
end

return config
