local types = require "deimos.types"
local load_file = require "deimos.parser.load_file"

local DEFAULT_CORE_SIZE = 8000

---Instruction used to initialize core
---@type Insn
local INITIAL_INSN = load_file.parse_insn("DAT.F #0, #0") --[[@as Insn]]

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
