local utils = require("utils")
local class = require("libs.class")

local input = {}

local binaryGamepadInputs = {
    "a", "b", "x", "y", "back", "guide", "start",
    "leftstick", "rightstick", "leftshoulder", "rightshoulder",
    "dpup", "dpdown", "dpleft", "dpright"
}
local analogGamepadInputs = {
    "leftx", "lefty", "rightx", "righty",
    "triggerleft", "triggerright"
}

local function isBinary(func)
    return type(func()) == "boolean"
end

local function isAnalog(func)
    return type(func()) == "number"
end

local Control = class("Control")

function Control:initialize(getState, isBinary)
    self.getState = getState
    self.isBinary = isBinary
    if self.isBinary then
        self.state = false
        self.lastState = false
        self.pressed = false
        self.released = false
    else
        self.state = 0
        self.lastState = 0
    end
end

function Control:update()
    self.lastState = self.state
    self.state = self.getState()

    if self.isBinary then
        self.pressed = self.state and not self.lastState
        self.released = not self.state and self.lastState
    end
end

function Control:call()
    return self.state
end

Control.__call = Control.call

local Controller = class("Controller")

function Controller:initialize(analogSlots, binarySlots)
    self.analogSlots = analogSlots
    self.binarySlots = binarySlots
    self.allSlots = utils.table.mergeLists(analogSlots, binarySlots)

    for _, name in ipairs(self.analogSlots) do
        self:bind(name, input.analogDummy())
    end
    for _, name in ipairs(self.binarySlots) do
        self:bind(name, input.binaryDummy())
    end
end

function Controller:bind(slot, getState)
    assert(utils.table.inList(self.allSlots, slot))
    local isBinarySlot = utils.table.inList(self.binarySlots, slot)
    assert(isBinarySlot and isBinary(getState) or isAnalog(getState))
    self[slot] = Control(getState, isBinarySlot)
end

function Controller:update()
    for _, slot in ipairs(self.allSlots) do
        self[slot]:update()
    end
end

input.Control = Control
input.Controller = Controller

---- getState helpers

function input.gamepadButton(joystick, button)
    return function()
        return joystick:isGamepadDown(button)
    end
end

function input.gamepadAxis(joystick, axis)
    return function()
        return joystick:getGamepadAxis(axis)
    end
end

function input.gamepadWrapper(joystick)
    local ret = {}
    for _, button in ipairs(binaryGamepadInputs) do
        ret[button] = input.gamepadButton(joystick, button)
    end
    for _, axis in ipairs(analogGamepadInputs) do
        ret[axis] = input.gamepadAxis(joystick, axis)
    end
    return ret
end

input.keyboardWrapper = setmetatable({}, {
    __index = function(kb, key)
        return function()
            return love.keyboard.isDown(key)
        end
    end
})

function input.keyboard(key)
    return function()
        return love.keyboard.isDown(key)
    end
end

function input.mouse(button)
    return function()
        return love.mouse.isDown(button)
    end
end

function input.mousePos(axis)
    return function()
        return select(axis, love.mouse.getPosition())
    end
end

local function _binaryDummy()
    return false
end

function input.binaryDummy()
    return _binaryDummy
end

local function _analogDummy()
    return 0
end

function input.analogDummy()
    return _analogDummy
end

function input.toanalog(plus, minus)
    assert(isBinary(plus))
    assert(isBinary(minus))
    return function()
        return (plus() and 1 or 0) - (minus() and 1 or 0)
    end
end

function input.thresh(analog, value)
    assert(isAnalog(analog))
    return function()
        if value > 0 then
            return analog() > value
        else
            return analog() < value
        end
    end
end

function input._and(...)
    local args = {...}
    for _, arg in ipairs(args) do
        assert(isBinary(arg))
    end

    return function()
        for _, arg in ipairs(args) do
            if not arg() then
                return false
            end
        end
        return true
    end
end

function input._or(...)
    local args = {...}
    for _, arg in ipairs(args) do
        assert(isBinary(arg))
    end

    return function()
        for _, arg in ipairs(args) do
            if arg() then
                return true
            end
        end
        return false
    end
end

return input
