local const = require("constants")
local utils = require("utils")
local vmath = require("utils.vmath")
local GameObject = require("gameobject")
local net = require("net")

local audio = {}

local rootPath = "media/sounds/"

local soundMap = {
    attack = "attack.wav",
    breakOpen = "break.wav",
    dash = "dash.wav",
    die = "die.wav",
    fallimpact = "fallimpact.wav",
    jump = "jump.wav",
    shorthop = "shorthop.wav",
    open = "open.wav",
    parry = "parry.wav",
    runstep = "runstep.wav",
    step = "step.wav",
    wallhit = "wallhit.wav",
    wavedash = "wavedash.wav",
}

local sounds = {}

audio.listener = {0, 0}

function audio.load()
    for name, file in pairs(soundMap) do
        local normal, lowpassed
        assert(type(file) == "string" or type(file) == "table")
        if type(file) == "string" then
            normal, lowpassed = file, "lowpassed/" .. file
        elseif type(file) == "table" then
            assert(#file == 2)
            normal, lowpassed = file[1], file[2]
        end

        sounds[name] = {
            normal = love.audio.newSource(rootPath ..normal),
            lowpassed = love.audio.newSource(rootPath .. lowpassed),
        }
    end
end

function audio.atten(soundName, dist)
    local atten, min, max = utils.table.unpackKeys(
        const.sound.attenData.default, {"atten", "min", "max"})
    if const.sound.attenData[soundName] then
        atten = const.sound.attenData[soundName].atten or atten
        min = const.sound.attenData[soundName].min or min
        max = const.sound.attenData[soundName].max or max
    end

    if dist < min then
        return 1.0
    elseif dist > max then
        return 0.0
    else
        local t = (dist - min) / (max - min)
        if atten == "linear" then
            return 1.0 - t
        elseif atten == "log" then
            return math.min(1, -const.sound.logAttenFactor * math.log(t))
        elseif atten == "inverse" then
            return math.min(1, const.sound.inverseAttenFactor / t)
        end
    end
end

local function play(name, x, y)
    assert(sounds[name], "Unknown sound: " .. name)
    assert(x, "Must pass position to audio.play!")
    if y == nil then
        x, y = x[1], x[2]
    end
    local pos = {x, y}
    local sound = sounds[name]

    local rel = vmath.sub(audio.listener, {x, y})
    local dist = vmath.len(rel)
    local dir = vmath.mul(rel, 1/dist)
    local volume = const.sound.masterVolume
    volume = volume * (const.sound.baseVolume[name] or 1.0)
    volume = volume * audio.atten(name, dist)

    local occluded = false
    for _, object in ipairs(GameObject.world) do
        if object.solid and not object.transparent then
            local ts = object.shape:intersectionsWithRay(x, y, dir[1], dir[2])
            for _, t in ipairs(ts) do
                if t > 0 and t < dist then
                    occluded = true
                    break
                end
            end
        end
    end

    local inst
    if occluded then
        sound.lowpassed:play():setVolume(volume * const.sound.occlusionVolumeFactor)
    else
        inst = sound.normal:play():setVolume(volume)
    end
end

local playRpc = net.Rpc(function(name, x, y)
    if not net.hosting then
        play(name, x, y)
    end
end)

function audio.play(name, x, y)
    playRpc(name, x, y)
end

return audio
