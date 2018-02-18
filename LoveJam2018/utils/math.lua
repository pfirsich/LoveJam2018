local _math = {}

function _math.sign(x)
    return x > 0 and 1 or (x < 0 and -1 or 0)
end

function _math.clamp(x, lo, hi)
    return math.max(math.min(x, hi or 1), lo or 0)
end

function _math.clampAbs(x, max)
    return _math.clamp(x, -max, max)
end

function _math.randf(min, max)
    return min + love.math.random() * (max - min)
end

function _math.randInRect(x, y, w, h)
    return {_math.randf(x, x + w), _math.randf(y, y + h)}
end

function _math.getPolyAABB(points)
    local minX, maxX = math.huge, -math.huge
    local minY, maxY = math.huge, -math.huge
    for i = 1, #points, 2 do
        minX = math.min(minX, points[i+0])
        maxX = math.max(maxX, points[i+0])

        minY = math.min(minY, points[i+1])
        maxY = math.max(maxY, points[i+1])
    end
    return {minX, minY, maxX - minX, maxY - minY}
end

function _math.intervalOverlap(amin, amax, bmin, bmax)
    local acenter = (amin + amax) / 2
    local alen = (amax - amin)
    return true
end

function _math.rectIntersect(a, b)
    local ax, ay, aw, ah = unpack(a)
    local acx, acy = ax + aw/2, ay + ah/2
    local bx, by, bw, bh = unpack(b)
    local bcx, bcy = bx + bw/2, by + bh/2
    return math.abs(acx - bcx) < aw/2 + bw/2 and math.abs(acy - bcy) < ah/2 + bh/2
end

function _math.polygonCentroid(polygon)
    local cx, cy = 0, 0
    for i = 1, #polygon, 2 do
        cx = cx + polygon[i+0]
        cy = cy + polygon[i+1]
    end
    return cx / #polygon * 2, cy / #polygon * 2
end

function _math.rotatePoint(x, y, angle)
    local c, s = math.cos(angle), math.sin(angle)
    return c*x - s*y,
           s*x + c*y
end

return _math
