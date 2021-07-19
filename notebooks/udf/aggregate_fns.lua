-- aggregate_fns.lua - stream UDF functions to implement aggregates

-- count and sum reducer
local function add_values(val1, val2)
    return (val1 or 0) + (val2 or 0)
end

-- count mapper
-- note closures are used to access aggregate parameters such as bin
local function rec_to_count_closure(bin)
    local function rec_to_count(rec) 
    -- if bin is specified: if bin exists in record return 1 else 0; if no bin is specified, return 1
        return (not bin and 1) or ((rec[bin] and 1) or 0)
    end
    return rec_to_count
end

-- count
function count(stream)
    return stream : map(rec_to_count_closure()) : reduce(add_values)
end

-- mapper for various single bin aggregates
local function rec_to_bin_value_closure(bin)
    local function rec_to_bin_value(rec)
    -- if a numeric bin exists in record return its value; otherwise return nil
        local val = rec[bin]
        if (type(val) ~= "number") then val = nil end
        return val
    end
    return rec_to_bin_value 
end

-- sum
function sum(stream, bin)
    return stream : map(rec_to_bin_value_closure(bin)) : reduce(add_values)
end


-- range filter
local function range_filter_closure(range_bin, range_low, range_high)
    local function range_filter(rec)
        -- if bin value is in [low,high] return true, false otherwise
        local val = rec[range_bin]
        if (not val or type(val) ~= "number") then val = nil end
        return (val and (val >= range_low and val <= range_high)) or false
    end
    return range_filter
end
    
-- sum of range: sum(sum_bin) where range_bin in [range_low, range_high]
function sum_range(stream, sum_bin, range_bin, range_low, range_high)
    return stream : filter(range_filter_closure(range_bin, range_low, range_high)) 
                    : map(rec_to_bin_value_closure(sum_bin)) : reduce(add_values)
end

-- min reducer
local function get_min(val1, val2)
    local min = nil
    if val1 then
        if val2 then
            if val1 < val2 then min = val1 else min = val2 end
        else min = val1 
        end
    else 
        if val2 then min = val2 end
    end
    return min
end

-- min
function min(stream, bin)
    return stream : map(rec_to_bin_value_closure(bin)) : reduce(get_min)
end
 
-- max reducer
local function get_max(val1, val2)
    local max = nil
    if val1 then
        if val2 then
            if val1 > val2 then max = val1 else max = val2 end
        else max = val1 
        end
    else 
        if val2 then max = val2 end
    end
    return max
end

-- max
function max(stream, bin)
    return stream : map(rec_to_bin_value_closure(bin)) : reduce(get_max)
end
   
-- map function to comoute average and range
local function compute_final_stats(stats)
    local ret = map();
    ret['AVERAGE'] = stats["sum"] / stats["count"]
    ret['RANGE'] = stats["max"] - stats["min"]
    return ret
end

-- merge partial stream maps into one
local function merge_stats(a, b)
    local ret = map()
    ret["sum"] = add_values(a["sum"], b["sum"])
    ret["count"] = add_values(a["count"], b["count"])
    ret["min"] = get_min(a["min"], b["min"])
    ret["max"] = get_max(a["max"], b["max"])
    return ret
end

-- aggregate operator to compute stream state for average_range
local function aggregate_stats(agg, val)
    agg["count"] = (agg["count"] or 0) + ((val["bin_avg"] and 1) or 0)
    agg["sum"] = (agg["sum"] or 0) + (val["bin_avg"] or 0)
    agg["min"] = get_min(agg["min"], val["bin_range"])
    agg["max"] = get_max(agg["max"], val["bin_range"])
    return agg
end

-- average_range
function average_range(stream, bin_avg, bin_range)
    local function rec_to_bins(rec)
        -- extract the values of the two bins in ret 
        local ret = map()
        ret["bin_avg"] = rec[bin_avg]
        ret["bin_range"] = rec[bin_range]
        return ret
    end
    return stream : map(rec_to_bins) : aggregate(map(), aggregate_stats) : reduce(merge_stats) : map(compute_final_stats)
end

-- nested map merge for group-by sum/count; explicit map merge at each nested level
local function merge_group_sum(a, b)
    local function merge_group(x, y)
    -- inner map merge
        return map.merge(x, y, add_values)
    end
    -- outer map merge
    return map.merge(a, b, merge_group)
end

-- aggregate for group-by sum
--    creates a map for each distinct group value and adds the value tagged for a group to the group's sum
local function group_sum(agg, groupval)
    if not agg[groupval["group"]] then agg[groupval["group"]] = map() end
    agg[groupval["group"]]["sum"] = (agg[groupval["group"]]["sum"] or 0) + (groupval["value"] or 0)
    return agg
end

-- group-by with sum
function groupby_with_sum(stream, bin_grpby, bin_sum)
    local function rec_to_group_and_bin(rec)
    -- tag the group by bin_grpby value, return a map containing group and bin_sum value 
        local ret = map()
        ret["group"] = rec[bin_grpby]
        local val = rec[bin_sum]
        if (not val or type(val) ~= "number") then val = 0 end
        ret["value"] = val
        return ret
    end
    return stream : map(rec_to_group_and_bin) : aggregate(map(), group_sum) : reduce(merge_group_sum) 
end

-- aggregate for group-by count
--   creates a map for each distinct group value and increments the tagged group's count
local function group_count(agg, group)
    if not agg[group] then agg[group] = map() end
    agg[group]["count"] = (agg[group]["count"] or 0) + ((group and 1) or 0)
    return agg
end

-- map function for group-by processing
local function rec_to_group_closure(bin_grpby)
    local function rec_to_group(rec)
        -- returns group-by bin value in a record
        return rec[bin_grpby]
    end
    return rec_to_group
end

-- group-by having example: count(*) having low <= count <= high
function groupby_with_count_having(stream, bin_grpby, having_range_low, having_range_high)
    local function process_having(stats)
        -- filters groups with count in the range
        local ret = map()
        for key, value in map.pairs(stats) do 
            if (key >= having_range_low and key <= having_range_high) then 
                ret[key] = value
            end
        end
        return ret
    end
    return stream : map(rec_to_group_closure(bin_grpby)) : aggregate(map(), group_count) 
                    : reduce(merge_group_sum) : map(process_having)
end

-- group-by count(*) order-by count
function groupby_with_count_orderby(stream, bin_grpby, bin_orderby)
    local function orderby(t, order)
        -- collect the keys
        local keys = {}
        for k in pairs(t) do keys[#keys+1] = k end
        -- sort by the order by passing the table and keys a, b,
        table.sort(keys, function(a,b) return order(t, a, b) end)
        -- return the iterator function
        local i = 0
        return function()
            i = i + 1
            if keys[i] then
                return keys[i], t[keys[i] ]
            end
        end
    end
    local function process_orderby(stats)
        -- uses lua table sort to sort aggregate map into a list 
        -- list has k and v separately added for sorted entries 
        local ret = list()
        local t = {}
        for k,v in map.pairs(stats) do t[k] = v end
        for k,v in orderby(t, function(t, a, b) return t[a][bin_orderby] < t[b][bin_orderby] end) do
            list.append(ret, k)
            list.append(ret, v)
        end        
        return ret
    end
    return stream : map(rec_to_group_closure(bin_grpby)) : aggregate(map(), group_count) 
                    : reduce(merge_group_sum) : map(process_orderby)
end

-- return map keys in a list
local function map_to_list(values)
    local ret = list()
    for k in map.keys(values) do list.append(ret, k) end
    return ret
end

-- merge partial aggregate maps
local function merge_values(a, b)
    return map.merge(a, b, function(v1, v2) return ((v1 or v2) and 1) or nil end)
end

-- map for distinct; using map unique keys
local function distinct_values(agg, value)
    if value then agg[value] = 1 end
    return agg
end

-- distinct 
function distinct(stream, bin)
    local function rec_to_bin_value(rec)
        -- simply return bin value in rec
        return rec[bin]
    end
    return stream : map(rec_to_bin_value) : aggregate(map(), distinct_values) 
                    : reduce(merge_values) : map(map_to_list)
end 
    
-- limit 
function limit(stream, bin, max)
   local function list_limit(agg, rec)
        -- add to list if the list size is below the limit
        if list.size(agg) < max then
            local ret = map()
            ret[bin] = rec[bin]
            list.append(agg, ret)
        end
        return agg
    end
    local function list_merge_limit(a, b)
        local ret = list()
        list.concat(ret, list.take(a, max))
        list.concat(ret, list.take(b, (max > list.size(ret) and max-list.size(ret)) or 0))
        return ret
    end
    return stream : aggregate(list(), list_limit) : reduce(list_merge_limit) 
end 
    
-- top n
function top_n(stream, bin, n)
    local function get_top_n(values)
        -- return top n values in a map as an ordered list
        -- uses lua table sort
        local t = {}
        local i = 1
        for k in map.keys(values) do 
            t[i] = k 
            i = i + 1
        end
        table.sort(t, function(a,b) return a > b end)
        local ret = list()
        local i = 0
        for k, v in pairs(t) do 
            list.append(ret, v) 
            i = i + 1 
            if i == n then break end
        end
        return ret
    end
    local function top_n_values(agg, value)
        if value then agg[value] = 1 end
        -- if map size exceeds n*10, trim to top n
        if map.size(agg) > n*10 then 
            local new_agg = map()
            local trimmed = trim_to_top_n(agg) 
            for value in list.iterator(trimmed) do
                new_agg[value] = 1
            end
            agg = new_agg
        end
        return agg
    end
    return stream : map(rec_to_bin_value_closure(bin)) : aggregate(map(), top_n_values) 
                    : reduce(merge_values) : map(get_top_n)
end 
