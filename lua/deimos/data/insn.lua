---@enum Mode
local Mode = {
    Immediate = "#",
    Direct = "$",
    Indirect = "@",
    -- TODO: Support pMARS ICWS 94 extensions
    -- PreDecrementA = "{",
    -- PostDecrementA = "}",
    PreDecrementB = "<",
    PostIncrementB = ">",
}

---@type table<string, Mode>
local ModesByChar = {}
for mode, c in pairs(Mode) do
    ModesByChar[c] = mode
end

---Check if a character is a valid mode
---@param c string Character to check
---@return boolean
local function is_mode_char(c)
    return ModesByChar[c] ~= nil
end

---@enum Modifier
local Modifier = {
    AB = "AB",
    BA = "BA",
    A = "A",
    B = "B",
    F = "F",
    X = "X",
    I = "I",
}

---@enum Opcode
local Opcode = {
    DAT = "DAT",
    MOV = "MOV",
    ADD = "ADD",
    SUB = "SUB",
    MUL = "MUL",
    DIV = "DIV",
    MOD = "MOD",
    JMP = "JMP",
    JMZ = "JMZ",
    JMN = "JMN",
    DJN = "DJN",
    CMP = "CMP",
    SLT = "SLT",
    SPL = "SPL",
    -- TODO: Support pMARS ICWS 94 extensions
    -- LDP = "LDP",
    -- STP = "STP",
    -- SEQ = "SEQ",
    -- SNE = "SNE",
    -- NOP = "NOP",
}

---@class Insn
---@field opcode Opcode
---@field modifier Modifier
---@field a_mode Mode
---@field a_number integer
---@field b_mode Mode
---@field b_number integer
local Insn = {
    Mode = Mode,
    Modifier = Modifier,
    Opcode = Opcode,
    is_mode_char = is_mode_char
}

function Insn:new(fields)
    local o = {
        opcode = fields.opcode,
        modifier = fields.modifier,
        a_mode = fields.a_mode,
        a_number = fields.a_number,
        b_mode = fields.b_mode,
        b_number = fields.b_number,
    }

    setmetatable(o, self)
    self.__index = self
    return o
end

---Compute string representation of instruction
---@return string
function Insn:format()
    return string.format(
        "%s.%s %s%d, %s%d",
        self.opcode,
        self.modifier,
        self.a_mode,
        self.a_number,
        self.b_mode,
        self.b_number
    )
end

return Insn
