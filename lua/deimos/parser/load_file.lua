local types = require "deimos.types"

local opcode_pat = "(%a%a%a)[ \t]*"
local modifier_pat = "(%a%a?)[ \t]*"
local mode_pat = "([#$@<>])[ \t]*"
local operand_pat = "([+%-]?%d+)[ \t]*"

local insn_pat = string.format(
    "^%s%%.[ \t]*%s%s%s,[ \t]*%s%s$",
    opcode_pat,
    modifier_pat,
    mode_pat,
    operand_pat,
    mode_pat,
    operand_pat
)

-- TODO: Return more informative errors from the parsing routines
-- They already have enough context to return specific information

---Parse a single instruction
---@param input string Source code for instruction
---@return Insn | nil # Parsed instruction, or nil if parse failed
local function parse_insn(input)
    local opcode, modifier, a_mode, a_number, b_mode, b_number =
        string.match(input, insn_pat)
    if opcode == nil then
        return nil
    elseif types.Opcode[opcode:upper()] == nil then
        return nil
    elseif types.Modifier[modifier:upper()] == nil then
        return nil
    elseif not types.is_mode_char(a_mode) then
        return nil
    elseif not types.is_mode_char(b_mode) then
        return nil
    end
    return {
        opcode = opcode:upper(),
        modifier = modifier:upper(),
        a_mode = a_mode,
        a_number = tonumber(a_number),
        b_mode = b_mode,
        b_number = tonumber(b_number)
    }
end

---Parse a single ORG pseudo-instruction
---@param input string Source code for ORG instruction
---@return OrgInsn | nil # Parsed ORG instruction, or nil if parse failed
local function parse_org_insn(input)
    local insn = nil
    local org = input:match("^[oO][rR][gG][ \t]*(%d+)[ \t]*$")
    if org ~= nil then
        insn = { org = tonumber(org) }
    end
    return insn
end

---Parse a load file into a program
---@param input string Source code for load file
---@return WarriorProgram | nil # Parsed program, or nil if parse failed
local function parse_load_file(input)
    ---@type WarriorProgram
    local program = {
        metadata = {},
        insns = {}
    }

    for line in input:gmatch("[^\r\n]+") do
        -- NB: Strip trailing/leading whitespace
        line = line:gsub("^%s*(.-)%s*$", "%1")

        -- TODO: Extract metadata from comments

        -- NB: Strip trailing comment
        line = line:match("^([^;]*);") or line

        if #line ~= 0 then
            local insn = parse_insn(line) or parse_org_insn(line)
            if insn == nil then
                return nil
            end
            table.insert(program.insns, insn)
        end
    end

    return program
end

return {
    parse_insn = parse_insn,
    parse_load_file = parse_load_file,
}
