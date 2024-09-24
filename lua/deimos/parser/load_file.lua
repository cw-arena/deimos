local lpeg = require "lpeg"
local c = require "deimos.parser.common"

local instruction = c.opcode * c.dot * c.modifier
    * c.mode * c.number * c.comma
    * c.mode * c.number * (c.comment ^ -1)
    / (function(opcode, modifier, aMode, aNumber, bMode, bNumber)
        return {
            opcode = opcode,
            modifier = modifier,
            aMode = aMode,
            aNumber = aNumber,
            bMode = bMode,
            bNumber = bNumber
        }
    end)
local single_instruction = instruction * lpeg.P(-1)

local org_instruction = c.org * c.number * (c.comment ^ -1)
    / (function(addr)
        return { org = addr }
    end)

local line = c.whitespace * ((c.comment + instruction + org_instruction) ^ 0)
local list = lpeg.Ct(line * ((c.newline * line) ^ 0))
local load_file = (c.newline ^ 0) * list * (c.newline ^ 0) * lpeg.P(-1)

---Parse a single instruction
---@param input string Source code for instruction
---@return Insn | nil # Parsed instruction, or nil if parse failed
local function parse_insn(input)
    return single_instruction:match(input)
end

---Parse a load file into a program
---@param input string Source code for load file
---@return WarriorProgram | nil # Parsed program, or nil if parse failed
local function parse_load_file(input)
    local insns = load_file:match(input) --[[@as Insn[] | nil]]
    if insns == nil then
        return nil
    end
    return {
        -- TODO: Extract metadata from comments
        metadata = {},
        insns = insns,
    }
end

return {
    parse_insn = parse_insn,
    parse_load_file = parse_load_file,
}
