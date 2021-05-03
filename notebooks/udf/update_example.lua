-- update_example.lua

function multiplyBy(rec, binName, factor)
    rec[binName] = rec[binName] * factor
    aerospike:update(rec)
end

function increment(rec, binName, value)
    rec[binName] = rec[binName] + value
    aerospike:update(rec)
end

function increment_and_get(rec, binName, value)
    local ret = map()                     -- Initialize the return value (a map)
    rec[binName] = rec[binName] + value
    ret[binName] = rec[binName]
    aerospike:update(rec)
    return ret
end

-- update the specified bins by adding and appending the values provided
function add_append(rec, binName1, addVal, binName2, appendVal)
    rec[binName1] = rec[binName1] + addVal
    rec[binName2] = rec[binName2] .. appendVal
    aerospike:update(rec)
end