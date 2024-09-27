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

---@enum MatchStatus
local MatchStatus = {
    RUNNING = "RUNNING",
    WIN = "WIN",
    TIE = "TIE",
}

---@alias Insn { opcode: Opcode, modifier: Modifier, a_mode: Mode, a_number: integer, b_mode: Mode, b_number: integer }
---@alias OrgInsn { org: integer }

---Pretty-print instruction into string
---@param insn Insn # Instruction to format
---@return string
local function formatInsn(insn)
    return string.format(
        "%s.%s %s%d, %s%d",
        insn.opcode,
        insn.modifier,
        insn.a_mode,
        insn.a_number,
        insn.b_mode,
        insn.b_number
    )
end

---@alias WarriorMetadata { name?: string, author?: string, strategy?: string }
---@alias WarriorProgram { metadata: WarriorMetadata, insns: (Insn | OrgInsn)[] }
---@alias WarriorTask { id: number, pc: integer }
---@alias WarriorTaskUpdate { next_pc?: integer, new_pc?: integer }
---@alias Warrior { id: string, tasks: TaskQueue, next_task_id: integer, program: WarriorProgram }

return {
    is_mode_char = is_mode_char,
    MatchStatus = MatchStatus,
    Mode = Mode,
    Modifier = Modifier,
    Opcode = Opcode,
    formatInsn = formatInsn,
}
