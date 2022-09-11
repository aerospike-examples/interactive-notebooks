-- Compare 'posted' bin value with provided value and update/create recent bin
function setRecent(record, value)
    if (record["posted"] >= value) then
        record["recent"] = true
    else
        record["recent"] = false
    end
    aerospike:update(record)
end

-- Get number of days between two dates
function getDaysBetween(record, date1, date2)
    function getDate(date)
        year = math.floor(date/10000)
        month = math.floor((date - (year * 10000))/100)
        day = math.floor(date - (year * 10000) - (month * 100))
        return os.time{year=year, month=month, day=day}
    end
    d1 = getDate(record[date1])
    d2 = getDate(record[date2])
    days = os.difftime(d1, d2) / (24 * 60 * 60)
    return math.abs(math.floor(days))
end

-- Aggregation function to count records
local function one(rec)
    return 1
end

local function add(a, b)
    return a + b
end

function count(stream)
    return stream : map(one) : reduce(add);
end