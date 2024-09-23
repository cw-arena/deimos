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
    A = "A",
    B = "B",
    AB = "AB",
    BA = "BA",
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

---
local DEFAULT_CORE_SIZE <const> = 8000

---Instruction used to initialize core
---@type Insn
local INITIAL_INSN <const> = {
    opcode = Opcode.DAT,
    modifier = Modifier.F,
    aMode = Mode.Indirect,
    aValue = 0,
    bMode = Mode.Indirect,
    bValue = 0,
}

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

---@class Mars
---@field core table<Address, Insn>
---@field cycles integer
---@field warriors Warrior[]
local Mars = {}

---@alias MarsOptions { core_size?: integer, initial_insn?: Insn }

---Create a new [Mars](lua://Mars)
---@param options MarsOptions
---@return Mars
function Mars:new(options)
    ---@type Mars
    local o = {
        core = {},
        cycles = 0,
        warriors = {},
    }

    local core_size = options.core_size or DEFAULT_CORE_SIZE
    local initial_insn = options.initial_insn or INITIAL_INSN

    for _ = 1, core_size do
        table.insert(o.core, clone(initial_insn))
    end

    setmetatable(o, self)
    self.__index = self
    return o
end

function Mars:run_cycle()

end
