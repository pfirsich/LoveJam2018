local utils = require("utils")

-- all constants are here to not pollute the global namespace
local const = {}

local function setupConstants()

end

local modified = utils.ModifiedChecker()

function const.reload(root, dontSetup)
    root = root or ""
    local suffix = ".constants.lua"
    for _, item in ipairs(lf.getDirectoryItems(root)) do
        local path = (root or "") .. "/" .. item
        if lf.isFile(path) then
            if item:sub(-suffix:len()) == suffix and modified(path) then
                local c = utils.loveDoFile(path)
                utils.table.updateTable(const, c)
            end
        elseif lf.isDirectory(path) then
            const.reload(path, true)
        end
    end

    if not dontSetup then
        setupConstants()
    end
end

return const
