-- TODO: TIDY THIS SHIT UP. ASAP

local camera = {
    -- config
    scaleMax = 1.0,
    scaleMin = 0.2,
    shakeIntensity = 0.0,
    screenShakeFreq = 10.0,

    -- set these
    target = {
        position = {0, 0},
        scale = 1,
    },

    -- don't set these yourself
    position = {0, 0},
    scale = 1,
}

function camera.push()
    love.graphics.push()
    -- Center Screen
    local shakeX, shakeY = camera.shakeFunction()
    local winW, winH = love.graphics.getDimensions()
    love.graphics.translate(winW/2  + shakeX * camera.shakeIntensity,
                            winH/2 + shakeY * camera.shakeIntensity)

    -- Here I swap scale and translate, so I can scale the translation myself and floor the values, to prevent sub-pixel-flickering around the edges
    local tx = -math.floor(camera.position[1] * camera.scale)
    local ty = -math.floor(camera.position[2] * camera.scale)
    love.graphics.translate(tx, ty)
    -- FIXME: flickering on edges caused by pixel positions not being whole numbers after scaling (see math.floor in translate). ?
    love.graphics.scale(camera.scale)
end

function camera.pop()
    love.graphics.pop()
end

local function smoothInto(from, to, factor)
    return from + (to - from) * factor
end

-- you should probably scale these factors with dt
function camera.approachTarget(posFactor, scaleFactor)
    if scaleFactor == nil then scaleFactor = posFactor end

    camera.position[1] = smoothInto(camera.position[1], camera.target.position[1], posFactor)
    camera.position[2] = smoothInto(camera.position[2], camera.target.position[2], posFactor)
    camera.scale = smoothInto(camera.scale, camera.target.scale, scaleFactor)
end

function camera.clampToBounds()
    local wW, wH = love.graphics.getDimensions()

    local scaleMin = camera.scaleMin

    if camera.bounds then
        -- don't zoom out too much, if bounds are too close to each other
        scaleMin = math.max(scaleMin, wW / camera.bounds[3])
    end

    camera.scale = math.max(camera.scale, scaleMin)
    camera.scale = math.min(camera.scale, camera.scaleMax)

    if camera.bounds then
        local x, y, w, h = unpack(camera.bounds)
        local deltaX = wW / camera.scale / 2
        local deltaY = wH / camera.scale / 2
        local minPosX = x + deltaX
        local maxPosX = x + w - deltaX
        local minPosY = y + deltaY
        local maxPosY = y + h - deltaY
        camera.position[1] = math.max(math.min(camera.position[1], maxPosX), minPosX)
        camera.position[2] = math.max(math.min(camera.position[2], maxPosY), minPosY)
    end
end

function camera.worldToScreen(x, y)
    local w, h = love.graphics.getDimensions()
    local tx = -math.floor(camera.position[1] * camera.scale)
    local ty = -math.floor(camera.position[2] * camera.scale)
    return x * camera.scale + tx + w/2, y * camera.scale + ty + h/2
end

function camera.screenToWorld(x, y)
    local w, h = love.graphics.getDimensions()
    local tx = -math.floor(camera.position[1] * camera.scale)
    local ty = -math.floor(camera.position[2] * camera.scale)
    return (x - w/2 - tx) / camera.scale, (y - h/2 - ty) / camera.scale
end

-- set the target scale so that all points fit the camera view
-- borders are applied on all side, where worldBorder is in world space and screenBorder in screen space
function camera.fitPoints(points, worldBorder, screenBorder, rotate)
    rotate = rotate or false
    worldBorder = worldBorder or 0
    screenBorder = screenBorder or 0

    local maxXDist, maxYDist = 0, 0
    for _, point in ipairs(points) do
        maxXDist = math.max(maxXDist, math.abs(camera.position[1] - point[1]) + worldBorder)
        maxYDist = math.max(maxYDist, math.abs(camera.position[2] - point[2]) + worldBorder)
    end

    local scrW, scrH = love.graphics.getDimensions()
    local scaleX = (scrW/2 - screenBorder) / maxXDist
    local scaleY = (scrH/2 - screenBorder) / maxYDist
    camera.target.scale = math.min(scaleX, scaleY)
    camera.target.scale = math.max(camera.scaleMin, camera.target.scale)
    camera.target.scale = math.min(camera.scaleMax, camera.target.scale)
end

function camera.focusPoints(points)
    local avgX, avgY = 0, 0
    local weightSum = 0
    for _, point in ipairs(points) do
        local x, y, weight = unpack(point)
        weight = weight or 1
        avgX = avgX + x * weight
        avgY = avgY + y * weight
        weightSum = weightSum + weight
    end
    camera.target.position[1] = avgX / weightSum
    camera.target.position[2] = avgY / weightSum
end

function camera.shakeFunction()
    local t = (love.timer.getTime() * camera.screenShakeFreq) % 10.0
    local offset = 0.5
    local x, y = love.math.noise(t) * 2.0 - 1.0, love.math.noise(t+offset) * 2.0 - 1.0
    return x, y
end

-- returns 2 2-tuples (top left - x, y), (bottom right - x, y)
function camera.getAABB()
    local tlX, tlY = camera.screenToWorld(0, 0)
    local brX, brY = camera.screenToWorld(love.graphics.getDimensions())
    return tlX, tlY, brX - tlX, brY - tlY
end

return camera
