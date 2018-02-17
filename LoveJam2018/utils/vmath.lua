local vmath = {}

function vmath.vec(x, y)
    return {x, y}
end

function vmath.add(a, b)
    return {a[1] + b[1], a[2] + b[2]}
end

function vmath.sub(a, b)
    return {a[1] - b[1], a[2] - b[2]}
end

function vmath.mul(a, s)
    return {a[1] * s, a[2] * s}
end

function vmath.copy(v)
    return {v[1], v[2]}
end

function vmath.len(v)
    return math.sqrt(v[1]*v[1] + v[2]*v[2])
end

function vmath.normed(v)
    local len = vmath.len(v) + 1e-5
    return {v[1] / len, v[2] / len}
end

function vmath.ortho(v)
    return {v[2], -v[1]}
end

function vmath.dot(a, b)
    return a[1]*b[1] + a[2]*b[2]
end

function vmath.angle(v)
    return math.atan2(v[2], v[1])
end

function vmath.split(v, normal)
    normal = vmath.normed(normal)
    local coeff = vmath.dot(v, normal)
    local vNormal = vmath.mul(normal, coeff)
    local vTangent = vmath.sub(v, vNormal)
    return vNormal, vTangent
end

return vmath
