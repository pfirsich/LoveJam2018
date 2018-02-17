local input = require("input")

local controller = {}

local analogSlots = {
    "moveX", "moveY", "aimX", "aimY",
}

local binarySlots =  {
    "sprint", "jump", "attack", "dash", "kunai", "use",
}

function controller.gamepad(joystick)
    local gp = input.gamepadWrapper(joystick)
    local ctrl = input.Controller(analogSlots, binarySlots)
    ctrl:bind("moveX", gp.leftx)
    ctrl:bind("moveY", gp.lefty)
    local triggerThresh = 0.8
    ctrl:bind("sprint", input._or(
        input.thresh(gp.triggerleft, triggerThresh),
        input.thresh(gp.triggerright, triggerThresh)
    ))
    ctrl:bind("jump", gp.a)
    ctrl:bind("attack", gp.x)
    ctrl:bind("dash", input._or(gp.leftshoulder, gp.rightshoulder))
    ctrl:bind("kunai", gp.b)
    ctrl:bind("use", gp.y)
    return ctrl
end

function controller.keyboard()
    local ctrl = input.Controller(analogSlots, binarySlots)
    local kb = input.keyboardWrapper
    ctrl:bind("moveX", input.toanalog(kb.d, kb.a))
    ctrl:bind("moveY", input.toanalog(kb.s, kb.w))
    ctrl.useAim = true
    ctrl:bind("aimX", input.mousePos(1))
    ctrl:bind("aimY", input.mousePos(2))
    ctrl:bind("sprint", kb.lctrl)
    ctrl:bind("jump", kb.space)
    ctrl:bind("attack", input.mouse(1))
    ctrl:bind("dash", kb.lshift)
    ctrl:bind("kunai", input.mouse(2))
    ctrl:bind("use", kb.e)
    return ctrl
end

function controller.dummy()
    return input.Controller(analogSlots, binarySlots)
end

return controller
