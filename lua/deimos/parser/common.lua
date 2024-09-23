local lpeg = require "lpeg"

local OPCODES = {
    "DAT",
    "MOV",
    "ADD",
    "SUB",
    "MUL",
    "DIV",
    "MOD",
    "JMP",
    "JMZ",
    "JMN",
    "DJN",
    "CMP",
    "SLT",
    "SPL",
}

local MODIFIERS = {
    "AB",
    "BA",
    "A",
    "B",
    "F",
    "X",
    "I"
}

local MODES = {
    "#",
    "$",
    "@",
    "<",
    ">"
}

local whitespace = lpeg.S(" \t") ^ 0
local newline = (lpeg.P("\r\n") + lpeg.P("\n\r") + lpeg.P("\r") + lpeg.P("\n")) ^ 1

local v = lpeg.P(1) - lpeg.S("\r\n")
local comment = lpeg.P(";") * (v ^ 0)

local dot = lpeg.P(".") * whitespace
local comma = lpeg.P(",") * whitespace
local org = lpeg.P("ORG") * whitespace

local number = ((lpeg.S("+-") ^ -1) * (lpeg.R("09") ^ 1) * whitespace) / tonumber

local function one_of(strings)
    local parser = nil
    for _, str in ipairs(strings) do
        if parser == nil then
            parser = lpeg.P(str)
        else
            parser = parser + lpeg.P(str)
        end
    end
    return lpeg.C(parser)
end

local opcode = one_of(OPCODES) * whitespace
local modifier = one_of(MODIFIERS) * whitespace
local mode = one_of(MODES) * whitespace

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
