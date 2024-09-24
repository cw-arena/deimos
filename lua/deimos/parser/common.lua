local lpeg = require "lpeg"
local types = require "deimos.types"

local whitespace = lpeg.S(" \t") ^ 0
local newline = lpeg.S("\r\n") ^ 1

local v = lpeg.P(1) - lpeg.S("\r\n")
local comment = lpeg.P(";") * (v ^ 0)

local dot = lpeg.P(".") * whitespace
local comma = lpeg.P(",") * whitespace
local org = (lpeg.P("ORG") + lpeg.P("org")) * whitespace

local number = ((lpeg.S("+-") ^ -1) * (lpeg.R("09") ^ 1) * whitespace) / tonumber

---Create a parser that accepts any value in an enum
---@param enum table<string, string>
local function parse_enum(enum)
    -- NB: Sort the enum values by length descending to match greedily
    ---@type string[]
    local values = {}
    for _, value in pairs(enum) do
        table.insert(values, value)
    end
    table.sort(values, function(a, b) return string.len(a) > string.len(b) end)

    local parser = nil
    for _, value in ipairs(values) do
        local str_parser = lpeg.P(value) + lpeg.P(string.lower(value))
        if parser == nil then
            parser = str_parser
        else
            parser = parser + str_parser
        end
    end
    return (parser / string.upper) * whitespace
end

local opcode = parse_enum(types.Opcode)
local modifier = parse_enum(types.Modifier)
local mode = parse_enum(types.Mode)

return {
    comma = comma,
    comment = comment,
    dot = dot,
    mode = mode,
    modifier = modifier,
    newline = newline,
    number = number,
    opcode = opcode,
    org = org,
    whitespace = whitespace,
}
