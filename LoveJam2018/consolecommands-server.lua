local const = require("constants")
local utils = require("utils")
local console = require("libs.console")
local config = require("config")
local server = require("net.server")

--[[
    loadmap <map>
    switchteams (wechselt atk/def und bei der nächsten runde)
    restartround (keept score, startet ne neue runde)
    restart (resettet score, startet neue runde)
    status (lists players with nickname-id mapping)

    moveatk <name>/<id>
    movedef <name>/<id>
    kick <name>/<id>--]]

console.help.adminpw = {section = "Server",
    "Set the admin password",
    "Display admin password without argument, sets it with argument"}
function console.commands.adminpw(arg)
    pw = utils.trim(arg)
    if pw:len() == 0 then
        console.print(("Current admin password: '%s'"):format(config.adminpw))
    else
        config.set("adminpw", pw)
        config.write()
        console.print(("Admin password set to: '%s'"):format(pw))
    end
end

console.help.maxplayers = {section = "Server",
    "Set the maximum player number",
    "Display maximum player number without argument, sets it with argument"}
function console.commands.maxplayers(arg)
    num = tonumber(arg)
    if not num then
        console.print(("Current maximum player number is %d"):format(server.maxPlayers))
    else
        server.mayPlayers = num
        console.print(("Maximum player number set to: '%s'"):format(num))
    end
end

function console.commands.map(arg)
    server.changeMap(utils.trim(arg))
end
