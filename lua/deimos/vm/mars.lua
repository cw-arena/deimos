local load_file = require "deimos.parser.load_file"
local types = require "deimos.types"
local TaskQueue = require "deimos.vm.task_queue"

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
---@field options MarsOptions
---@field core table<integer, Insn>
---@field cycles integer
---@field warriors_by_id table<string, Warrior>
local Mars = {}

---@alias MarsOptions { core_size?: integer, initial_insn?: Insn, read_distance?: integer, write_distance?: integer }

---Create a new [Mars](lua://Mars)
---@param options? MarsOptions
---@return Mars
function Mars:new(options)
    ---@type Mars
    local o = {
        options = options or {},
        core = {},
        cycles = 0,
        warriors_by_id = {},
    }

    -- TODO: Validate core size > 0
    -- TODO: Validate cycles before tie > 0
    -- TODO: Validate instruction limit
    -- TODO: Validate maxNumTasks > 0
    -- TODO: Validate read/write distance (> 0, multiple of core size)
    -- TODO: Validate minimum separation > 0
    -- TODO: Validate separation > 0 or RANDOM

    setmetatable(o, self)
    self.__index = self
    return o
end

---Prepare for a new match
---@param programs WarriorProgram[] Participating warrior programs
function Mars:initialize(programs)
    -- TODO: Validate #programs = num_warriors.length && num_warriors > 1

    local options = self.options
    local core_size = options.core_size or DEFAULT_CORE_SIZE
    local initial_insn = options.initial_insn or INITIAL_INSN

    self.core = {}
    for _ = 1, core_size do
        table.insert(self.core, clone(initial_insn))
    end

    self.cycles = 0
    self.warriors_by_id = {}

    local pc = 0
    for id, program in ipairs(programs) do
        self.warriors_by_id[id] = {
            id = tostring(id),
            tasks = TaskQueue:new({ id = 0, pc = pc }),
            next_task_id = 1,
            program = program,
        }

        for i, insn in ipairs(program.insns) do
            self.core[pc + i] = clone(insn)
        end

        -- TODO: Support random/minimum separation
        pc = pc + #program.insns + 1
    end
end

---Execute a single instruction from each living warrior
function Mars:execute_cycle()
    for _, warrior in pairs(self.warriors_by_id) do
        self:execute_warrior_insn(warrior)
    end
    local state = self:get_match_state()
    if state.status ~= types.MatchStatus.RUNNING then
        -- TODO: Implement 'mars.end' hook here
    end
    self.cycles = self.cycles + 1
end

---Get state of currently executing match
---@return { status: MatchStatus, warrior_ids: string[] }
function Mars:get_match_state()
    local warrior_ids = {}
    for id, _ in pairs(self.warriors_by_id) do
        table.insert(warrior_ids, id)
    end
    return {
        -- TODO: Compute status from living warriors
        status = types.MatchStatus.RUNNING,
        warrior_ids = warrior_ids,
    }
end

---Execute a single instruction from a warrior
---@param warrior Warrior Warrior to execute instruction from
function Mars:execute_warrior_insn(warrior)
    local task = warrior.tasks:dequeue() --[[@as WarriorTask]]

    -- TODO: Implement 'warrior.step' hook here
    local insn = self.core[self:index(task.pc)]
    local a_operand = self:compute_operand(task.pc, "A")
    local b_operand = self:compute_operand(task.pc, "B")

    -- TODO: Implement all opcode handlers
    ---@type table<Opcode, fun(): WarriorTaskUpdate>
    local opcode_handlers = {
        [types.Opcode.DAT] = function()
            return {}
        end,
    }

    local handler = opcode_handlers[insn.opcode]
    if handler == nil then
        error(string.format("unknown opcode %s at PC=%d", insn.opcode, task.pc))
    end

    -- TODO: Implement 'warrior.opcode' hook here
    local update = handler()

    -- TODO: Implement 'warrior.task_update' hook here
    if update.next_pc ~= nil then
        warrior.tasks:enqueue({ id = task.id, pc = update.next_pc })
    end

    if update.new_pc ~= nil then
        local task_id = warrior.next_task_id
        warrior.tasks:enqueue({ id = task_id, pc = update.new_pc })
        warrior.next_task_id = task_id + 1
    end

    if warrior.tasks:length() == 0 then
        -- TODO: Implement 'warrior.died' hook here
        self.warriors_by_id[warrior.id] = nil
    end
end

---Add offset to address while respecting distance limit
---@param core_size integer Number of instructions in core
---@param limit integer Maximum allowed distance
---@param addr integer Initial address
---@param offset integer Current offset
---@return integer # The clamped offset
local function clamp(core_size, limit, addr, offset)
    offset = (offset + core_size) % limit
    if offset > math.floor(limit / 2) then
        offset = offset + core_size - limit
    end
    return (addr + offset) % core_size
end

---Get the core index for a program counter
---@param pc integer Address of instruction
---@return integer # Instruction index into core
function Mars:index(pc)
    return (pc % #self.core) + 1
end

---Compute the A-number/B-number of an A-operand/B-operand.
---@param pc integer Address of instruction
---@param operand ("A" | "B") Which number to compute
function Mars:compute_operand(pc, operand)
    local read_distance = self.options.read_distance or #self.core
    local write_distance = self.options.write_distance or #self.core

    local read_pc = 0
    local write_pc = 0

    ---@type nil | integer
    local post_inc_pc = nil

    local insn = self.core[self:index(pc)]
    local mode = (operand == "A" and insn.aMode) or insn.bMode
    local value = (operand == "A" and insn.aNumber) or insn.bNumber

    if mode ~= types.Mode.Immediate then
        read_pc = clamp(#self.core, read_distance, pc, value)
        write_pc = clamp(#self.core, write_distance, pc, value)

        if mode ~= types.Mode.Direct then
            -- TODO: Add support for PreDecrementA
            if mode == types.Mode.PreDecrementB then
                local predec_insn = self.core[self:index(write_pc)]
                predec_insn.bNumber = (predec_insn.bNumber + #self.core - 1) % #self.core
                -- TODO: Add support for PostIncrementA
            elseif mode == types.Mode.PostIncrementB then
                post_inc_pc = write_pc
            end

            read_pc = clamp(#self.core, read_distance, read_pc, self.core[self:index(read_pc)].bNumber)
            write_pc = clamp(#self.core, write_distance, write_pc, self.core[self:index(write_pc)].bNumber)
        end
    end

    -- TODO: Add support for PostIncrementA
    if post_inc_pc ~= nil then
        local post_inc_index = self:index(post_inc_pc)
        self.core[post_inc_index].bNumber = self.core[post_inc_index].bNumber + 1
    end

    return {
        insn = self.core[self:index(read_pc)],
        read_pc = read_pc,
        write_pc = write_pc
    }
end

return Mars
