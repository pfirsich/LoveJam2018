local const = require("constants")
local utils = require("utils")
local console = require("libs.console")
local game = require("scenes.game")
local config = require("config")
local client = require("net.client")

local commands = {}

local progressHandler = {text = "", keypressed = utils.nop}

function progressHandler.enter()
    progressHandler.progress = 0
    progressHandler.title = ""
    progressHandler.setText()
end

function progressHandler.update()
    progressHandler.progress = progressHandler.progress + const.SIM_DT
    progressHandler.setText()
end

function progressHandler.setText()
    local n = math.floor(progressHandler.progress)
    local t = progressHandler.progress - n
    if n % 2 == 0 then
        t = 1 - t
    end
    local width = 30
    local text = "\n\n\n    " .. progressHandler.title .. "\n    ["
    for i = 1, math.floor(t*width) do text = text .. "-" end
    text = text .. "O"
    for i = 1, width - math.floor(t*width) do text = text .. "-" end
    text = text .. "]"
    progressHandler.text = text
end

function commands.showProgress(title)
    console.takeOver(progressHandler)
    progressHandler.title = title
end

function console.commands.progress(str)
    commands.showProgress("Progressing...")
end

console.help.controls = {section = "Client",
    "Configure controls",
    "List controls without arguments, set controls with arguments"}
function console.commands.controls(args)
    local arg = utils.trim(args)
    local options = {"keyboard"}
    local optionsData = {keyboard = -1}
    local joysticks = love.joystick.getJoysticks()
    for i, joystick in ipairs(joysticks) do
        if joystick:isGamepad() then
            table.insert(options, "gamepad" .. i)
            optionsData["gamepad" .. i] = i
        end
    end
    if optionsData[arg] then
        if optionsData[arg] < 0 then
            game.setController()
        else
            game.setController(joysticks[optionsData[arg]])
        end
    else
        console.print("Possible options:")
        console.print("    keyboard")
        for i, joystick in ipairs(joysticks) do
            if joystick:isGamepad() then
                console.print("    gamepad" .. i .. " - " .. joystick:getName())
            end
        end
    end
end

console.help.quit = {section = "Client",
    "Quit the game"}
function console.commands.quit()
    love.event.quit()
end

console.help.nickname = {section = "Client",
    "Set nickname"}
function console.commands.nickname(name)
    name = utils.trim(name)
    if name:len() == 0 then
        console.print(("Current nickname: '%s'"):format(config.nickname))
    else
        config.set("nickname", name)
        config.write()
        console.print(("Nickname set to: '%s'"):format(name))
    end
end

console.help.savedir = {section = "Client",
    "Open save directory"}
function console.commands.savedir()
    love.system.openURL(lf.getSaveDirectory())
end

function console.commands.admin(cmd)
    cmd = utils.trim(cmd)
    if cmd:len() == 0 then
        console.prompt("Please enter the admin password of the server:", function(pw)
            -- auth
        end)
    else
        -- send command and execute remotely
    end
end

function console.commands.team(cmd)
    client.teamScreen()
end

function console.commands.volume(cmd)
    local vol = tonumber(cmd)
    if vol then
        love.audio.setVolume(vol)
    else
        console.print("Volume: " .. love.audio.getVolume())
    end
end

return commands
