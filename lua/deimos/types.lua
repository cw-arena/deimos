---@enum Mode
local Mode = {
    Immediate = "#",
    Direct = "$",
    Indirect = "@",
    PreDecrementA = "{",
    PostDecrementA = "}",
    PreDecrementB = "<",
    PostDecrementB = ">",
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
}

---@alias Insn { opcode: Opcode, modifier: Modifier, aMode: Mode, aValue: integer, bMode: Mode, bValue: integer }

---@alias WarriorMetadata { name?: string, author?: string, strategy?: string }
---@alias WarriorProgram { id: string, metadata: WarriorMetadata }

---@alias TaskID integer
---@alias Address integer
---@alias Warrior { program: WarriorProgram, next_task_id: integer, tasks: [TaskID, Address] }

return {
    Mode = Mode,
    Modifier = Modifier,
    Opcode = Opcode,
}
