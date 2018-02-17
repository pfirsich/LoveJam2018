local tableUtils = {}

function tableUtils.updateTable(tbl, with)
    for k, v in pairs(with) do
        tbl[k] = v
    end
end

function tableUtils.enum(list)
    local enum = {}
    local counter = 0
    for i = 1, #list do
        enum[list[i]] = counter
        counter = counter + 1
    end
    return enum
end

function tableUtils.mergeLists(...)
    local ret = {}
    for i = 1, select("#", ...) do
        tableUtils.extend(ret, select(i, ...))
    end
    return ret
end

function tableUtils.extend(a, b)
    if not b then
        return a
    end

    for _, item in ipairs(b) do
        table.insert(a, item)
    end

    return a
end

function tableUtils.indexOf(list, elem)
    for i, v in ipairs(list) do
        if v == elem then return i end
    end
    return nil
end

function tableUtils.inList(list, elem)
    return tableUtils.indexOf(list, elem) ~= nil
end

function tableUtils.inverseTable(tbl)
    local ret = {}
    for k, v in pairs(tbl) do
        ret[v] = k
    end
    return ret
end

-- TODO: implement, step, negative indices
function tableUtils.slice(tbl, from, to)
    from = from or 1
    to = to or #tbl
    local ret = {}
    for i = from, to do
        table.insert(ret, tbl[i])
    end
    return ret
end

function tableUtils.unpackKeys(tbl, keys)
    if #keys == 0 then
        return nil
    elseif #keys == 1 then
        return tbl[keys[1]]
    else
        return tbl[keys[1]], tableUtils.unpackKeys(tbl, tableUtils.slice(keys, 2))
    end
end

function tableUtils.stableSort(list, cmp)
    for i = 2, #list do
        local v = list[i]
        local j = i
        while j > 1 and cmp(v, list[j-1]) do
            list[j] = list[j-1]
            j = j - 1
        end
        list[j] = v
    end
end

return tableUtils
