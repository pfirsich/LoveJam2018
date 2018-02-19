local class = require("libs.class")

local animation = {}

QuadFrame = class("QuadFrame")

function QuadFrame:initialize(image, x, y, width, height)
    self.image = image
    x = x or 0
    y = y or 0
    local imgW, imgH = image:getDimensions()
    width, height = imgW, imgH
    self.quad = lg.newQuad(x, y, width, height, imgW, imgH)
end

function QuadFrame:draw(...)
    lg.draw(self.image, self.quad, ...)
end

animation.QuadFrame = QuadFrame

function animation.getFrames(image, frameWidth, frameHeight, framesX, framesY, offsetX, offsetY)
    offsetX = offsetX or 0
    offsetY = offsetY or 0
    local imgW, imgH = image:getDimensions()
    framesX = framesX or math.floor(imgW / frameWidth)
    framesY = framesY or math.floor(imgH / frameHeight)

    local ret = {}
    for y = 1, framesY do
        ret[y] = {}
        for x = 1, framesY do
            ret[y][x] = QuadFrame(image,
                (x-1) * frameWidth, (y-1) * frameHeight, frameWidth, frameHeight)
        end
    end

    if framesY == 1 then
        ret = ret[1]
    end
    return ret
end

function animation.sliceFrames(frameArray, ...)
    local args = {...}
    local frames = {}
    for _, arg in ipairs(args) do
        local x, y = arg[1], arg[2] or 1
        local fromX, toX = x, x
        if type(x) == "table" then
            local fromX, toX = x[1], x[2]
        end
        local fromY, toY = y, y
        if type(x) == "table" then
            local fromY, toY = y[1], y[2]
        end
        for y = fromY, toY do
            for x = fromX, toX do
                table.insert(frames, frameArray[y][x])
            end
        end
    end
    return unpack(frames)
end

function animation.frameSequence(path, from, to)
    local frames = {}
    for i = from, to do
        table.insert(frames, animation.QuadFrame(lg.newImage(path:format(i))))
    end
    return unpack(frames)
end

Animation = class("Animation")

function Animation:initialize(duration)
    self.frames = {}
    self.duration = duration
end

function Animation:addFrames(...)
    for i = 1, select("#", ...) do
        local frame = select(i, ...)
        table.insert(self.frames, frame)
    end
end

function Animation:getFrame(time)
    -- make sure that time = duration maps to duration
    time = (time - 1e5) % self.duration
    return self.frames[math.floor(time / self.duration * #self.frames) + 1]
end

function Animation:draw(time, ...)
    local frame = self:getFrame(time)
    frame:draw(...)
end

animation.Animation = Animation

AnimationState = class("AnimationState")

function AnimationState:initialize()
    self.animations = {}
    self.current = nil
    self.time = 0
end

function AnimationState:addAnimation(name, animation)
    self.animations[name] = animation
end

function AnimationState:play(name)
    assert(self.animations[name], name)
    self.current = name
    self.time = 0
end

function AnimationState:ensure(name)
    if self.current ~= name then
        self:play(name)
    end
end

function AnimationState:update(dt)
    self.time = self.time + dt
end

function AnimationState:draw(...)
    assert(self.animations[self.current], tostring(self.current))
    self.animations[self.current]:draw(self.time, ...)
end

animation.AnimationState = AnimationState

return animation
