---Make a copy of a table
---@param table table The table to copy
---@return table copy A shallow copy of the table
local function clone(table)
    local copy = {}
    for k, v in pairs(table) do
        copy[k] = v
    end
    return copy
end

---comment Check every table item against a predicate
---@generic T
---@param xs T[] Table to iterate over
---@param p fun(t: T): boolean Predicate to check with
---@return boolean # Whether every table item satisfied the predicate
local function every(xs, p)
    local ok = true
    for _, x in ipairs(xs) do
        if not p(x) then
            ok = false
            break
        end
    end
    return ok
end

---Zip two tables together
---@generic T, U
---@param xs T[] Left hand table
---@param ys U[] Right hand table
---@return [T, U][]
local function zip(xs, ys)
    local tbl = {}
    for i = 1, #xs do
        table.insert(tbl, { xs[i], ys[i] })
    end
    return tbl
end

---Format a value into a string representation
---@param x any
---@return unknown
local function dump(x)
    if type(x) ~= "table" then
        return tostring(x)
    end

    local s = ""
    for k, v in pairs(x) do
        if type(k) ~= "number" then
            k = string.format('"%s"', k)
        end
        s = s .. string.format("[%s] = %s,", k, dump(v))
    end
    return string.format("{ %s }", s)
end

return {
    clone = clone,
    dump = dump,
    every = every,
    zip = zip
}
