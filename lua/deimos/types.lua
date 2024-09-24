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
}

---@enum MatchStatus
local MatchStatus = {
    RUNNING = "RUNNING",
    WIN = "WIN",
    TIE = "TIE",
}

---@alias Insn { opcode: Opcode, modifier: Modifier, aMode: Mode, aValue: integer, bMode: Mode, bValue: integer }

---@alias WarriorMetadata { name?: string, author?: string, strategy?: string }
---@alias WarriorProgram { metadata: WarriorMetadata, insns: Insn[] }
---@alias WarriorTask { id: number, pc: integer }
---@alias WarriorTaskUpdate { next_pc?: integer, new_pc?: integer }
---@alias Warrior { id: string, tasks: TaskQueue, next_task_id: integer, program: WarriorProgram }

return {
    MatchStatus = MatchStatus,
    Mode = Mode,
    Modifier = Modifier,
    Opcode = Opcode,
}
