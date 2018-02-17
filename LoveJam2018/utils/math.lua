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

return _math
