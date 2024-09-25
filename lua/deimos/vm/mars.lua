local load_file         = require "deimos.parser.load_file"
local types             = require "deimos.types"
local TaskQueue         = require "deimos.vm.task_queue"
local lens              = require "deimos.vm.lens"
local utils             = require "deimos.utils"

local DEFAULT_CORE_SIZE = 8000

---Instruction used to initialize core
---@type Insn
local INITIAL_INSN      = load_file.parse_insn("DAT.F #0, #0") --[[@as Insn]]

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
        local j = 1
        local org = 0
        for _, insn in ipairs(program.insns) do
            if insn["org"] ~= nil then
                org = insn["org"]
            else
                self.core[pc + j] = clone(insn)
                j = j + 1
            end
        end

        self.warriors_by_id[tostring(id)] = {
            id = tostring(id),
            tasks = TaskQueue:new({ id = 0, pc = pc + org }),
            next_task_id = 1,
            program = program,
        }

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

---@type table<Modifier, [LensFactory, LensFactory]>
local MODIFIER_LENS_FACTORIES = {
    [types.Modifier.A] = { lens.a, lens.a },
    [types.Modifier.B] = { lens.b, lens.b },
    [types.Modifier.AB] = { lens.a, lens.b },
    [types.Modifier.BA] = { lens.b, lens.a },
    [types.Modifier.F] = { lens.ab, lens.ab },
    [types.Modifier.I] = { lens.ab, lens.ab },
    [types.Modifier.X] = { lens.ab, lens.ba },
}

---@alias OpcodeHandler fun(): WarriorTaskUpdate

---@type table<Opcode, fun(x: integer, y: integer): integer?>
local BINOPS = {
    [types.Opcode.ADD] = function(x, y) return x + y end,
    [types.Opcode.SUB] = function(x, y) return x + y end,
    [types.Opcode.MUL] = function(x, y) return x + y end,
    [types.Opcode.DIV] = function(x, y)
        if y == 0 then
            return nil
        end
        return math.floor(x / y)
    end,
    [types.Opcode.MOD] = function(x, y)
        if y == 0 then
            return nil
        end
        return x % y
    end,
}

---Execute a single instruction from a warrior
---@param warrior Warrior Warrior to execute instruction from
function Mars:execute_warrior_insn(warrior)
    local task = warrior.tasks:dequeue() --[[@as WarriorTask]]
    -- print("")
    -- print(string.format("task: id=>%d, pc=%d", task.id, task.pc))

    -- TODO: Implement 'warrior.step' hook here
    local insn = self:fetch(task.pc)
    -- print(string.format("insn=>%s", types.formatInsn(insn)))

    local a_operand = self:compute_operand(task.pc, "A")
    local b_operand = self:compute_operand(task.pc, "B")

    local lens_factories = MODIFIER_LENS_FACTORIES[insn.modifier]
    if lens_factories == nil then
        error(string.format("unknown modifier %s at PC=%d", insn.modifier, task.pc))
    end

    -- print(string.format("a_insn=>%s, a_read_pc=>%d", types.formatInsn(a_operand.insn), a_operand.read_pc))
    -- print(string.format("b_insn=>%s, b_read_pc=>%d", types.formatInsn(b_operand.insn), b_operand.read_pc))

    local a_lens = lens_factories[1](a_operand.insn)
    local b_lens = lens_factories[2](b_operand.insn)

    ---Generate an opcode handler for an arithmetic operation
    ---@param opcode Opcode Arithmetic opcode to handle
    ---@return OpcodeHandler
    local handle_arithmetic_opcode = function(opcode)
        return function()
            -- print(string.format("performing arith op %s", opcode))

            local update = { next_pc = (task.pc + 1) % #self.core }

            local as = a_lens:get()
            local bs = b_lens:get()

            -- print(string.format("%d (#%d elems)", as[1], #as))
            -- print(string.format("%d (#%d elems)", bs[1], #bs))

            for i = 1, #bs do
                local result = BINOPS[opcode](bs[i], as[i])
                if result == nil then
                    update = {}
                    break
                end

                bs[i] = result
                b_lens:set(bs)
            end

            return update
        end
    end

    ---@type table<Opcode, OpcodeHandler>
    local opcode_handlers = {
        --[[ 5.5.1 DAT
        No additional processing takes place.  This effectively removes the
        current task from the current warrior's task queue. ]]
        [types.Opcode.DAT] = function()
            return {}
        end,

        --[[ 5.5.2 MOV
        MOV replaces the B-target with the A-value and queues the next
        instruction (PC + 1). ]]
        [types.Opcode.MOV] = function()
            if insn.modifier == types.Modifier.I then
                -- print(string.format("writing %s to PC=%d", types.formatInsn(a_operand.insn), b_operand.write_pc))
                self:set(b_operand.write_pc, clone(a_operand.insn))
            else
                b_lens:set(a_lens:get())
            end
            return { next_pc = (task.pc + 1) % #self.core }
        end,

        --[[ 5.5.3 ADD
        ADD replaces the B-target with the sum of the A-value and the B-value
        (A-value + B-value) and queues the next instruction (PC + 1).  ADD.I
        functions as ADD.F would. ]]
        [types.Opcode.ADD] = handle_arithmetic_opcode(types.Opcode.ADD),

        --[[ 5.5.4 SUB
        SUB replaces the B-target with the difference of the B-value and the
        A-value (B-value - A-value) and queues the next instruction (PC + 1).
        SUB.I functions as SUB.F would. ]]
        [types.Opcode.SUB] = handle_arithmetic_opcode(types.Opcode.SUB),

        --[[ 5.5.5 MUL
        MUL replaces the B-target with the product of the A-value and the
        B-value (A-value * B-value) and queues the next instruction (PC + 1).
        MUL.I functions as MUL.F would. ]]
        [types.Opcode.MUL] = handle_arithmetic_opcode(types.Opcode.MUL),

        --[[ 5.5.6 DIV
        DIV replaces the B-target with the integral result of dividing the
        B-value by the A-value (B-value / A-value) and queues the next
        instruction (PC + 1).  DIV.I functions as DIV.F would. If the
        A-value is zero, the B-value is unchanged and the current task is
        removed from the warrior's task queue. ]]
        [types.Opcode.DIV] = handle_arithmetic_opcode(types.Opcode.DIV),

        --[[ 5.5.7 MOD
        MOD replaces the B-target with the integral remainder of dividing the
        B-value by the A-value (B-value % A-value) and queues the next
        instruction (PC + 1).  MOD.I functions as MOD.F would. If the
        A-value is zero, the B-value is unchanged and the current task is
        removed from the warrior's task queue. ]]
        [types.Opcode.MOD] = handle_arithmetic_opcode(types.Opcode.MOD),

        --[[ 5.5.8 JMP
        JMP queues the sum of the program counter and the A-pointer. ]]
        [types.Opcode.JMP] = function()
            return { next_pc = a_operand.read_pc }
        end,

        --[[ 5.5.9 JMZ
        JMZ tests the B-value to determine if it is zero.  If the B-value is
        zero, the sum of the program counter and the A-pointer is queued.
        Otherwise, the next instruction is queued (PC + 1).  JMZ.I functions
        as JMZ.F would, i.e. it jumps if both the A-number and the B-number
        of the B-instruction are zero. ]]
        [types.Opcode.JMZ] = function()
            local next_pc = (task.pc + 1) % #self.core
            if utils.every(b_lens:get(), function(v) return v == 0 end) then
                next_pc = a_operand.read_pc
            end
            return { next_pc = next_pc }
        end,

        --[[ 5.5.10 JMN
        JMN tests the B-value to determine if it is zero.  If the B-value is
        not zero, the sum of the program counter and the A-pointer is queued.
        Otherwise, the next instruction is queued (PC + 1).  JMN.I functions
        as JMN.F would, i.e. it jumps if both the A-number and the B-number
        of the B-instruction are non-zero. This is not the negation of the
        condition for JMZ.F. ]]
        [types.Opcode.JMN] = function()
            local next_pc = (task.pc + 1) % #self.core
            if utils.every(b_lens:get(), function(v) return v ~= 0 end) then
                next_pc = a_operand.read_pc
            end
            return { next_pc = next_pc }
        end,

        --[[ 5.5.11 DJN
        DJN decrements the B-value and the B-target, then tests the B-value
        to determine if it is zero.  If the decremented B-value is not zero,
        the sum of the program counter and the A-pointer is queued.
        Otherwise, the next instruction is queued (PC + 1).  DJN.I functions
        as DJN.F would, i.e. it decrements both both A/B-numbers of the B-value
        and the B-target, and jumps if both A/B-numbers of the B-value are
        non-zero. ]]
        [types.Opcode.DJN] = function()
            local next_pc = (task.pc + 1) % #self.core
            local xs = b_lens:update(function(x) return x - 1 end)
            if utils.every(xs, function(v) return v ~= 0 end) then
                next_pc = a_operand.read_pc
            end
            return { next_pc = next_pc }
        end,

        --[[ 5.5.12 CMP
        CMP compares the A-value to the B-value.  If the result of the
        comparison is equal, the instruction after the next instruction
        (PC + 2) is queued (skipping the next instruction).  Otherwise, the
        the next instruction is queued (PC + 1). ]]
        [types.Opcode.CMP] = function()
            local offset = 1
            local cond = false
            if insn.modifier == types.Modifier.I then
                cond = a_operand.insn.opcode == b_operand.insn.opcode
                    and a_operand.insn.modifier == b_operand.insn.modifier
                    and a_operand.insn.aMode == b_operand.insn.aMode
                    and a_operand.insn.aNumber == b_operand.insn.aNumber
                    and a_operand.insn.bMode == b_operand.insn.bMode
                    and a_operand.insn.bNumber == b_operand.insn.bNumber
            else
                local pairs = utils.zip(a_lens:get(), b_lens:get())
                cond = utils.every(pairs, function(p) return p[1] == p[2] end)
            end
            if cond then
                offset = offset + 1
            end
            return { next_pc = (task.pc + offset) % #self.core }
        end,

        --[[ 5.5.13 SLT
        SLT compares the A-value to the B-value.  If the A-value is less than
        the B-value, the instruction after the next instruction (PC + 2) is
        queued (skipping the next instruction).  Otherwise, the next
        instruction is queued (PC + 1).  SLT.I functions as SLT.F would.]]
        [types.Opcode.SLT] = function()
            local offset = 1
            local pairs = utils.zip(a_lens:get(), b_lens:get())
            if utils.every(pairs, function(p) return p[1] < p[2] end) then
                offset = offset + 1
            end
            return { next_pc = (task.pc + offset) % #self.core }
        end,

        --[[ 5.5.14 SPL
        SPL queues the next instruction (PC + 1) and then queues the sum of
        the program counter and A-pointer. If the queue is full, only the
        next instruction is queued.]]
        [types.Opcode.SPL] = function()
            return {
                next_pc = (task.pc + 1) % #self.core,
                new_pc = a_operand.write_pc
            }
        end
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

local function resolve(core_size, addr)
    while addr < 0 do
        addr = addr + core_size
    end
    return (addr % core_size) + 1
end

---Get the instruction at an address
---@param addr integer Address of instruction
---@return Insn
function Mars:fetch(addr)
    return self.core[resolve(#self.core, addr)]
end

---Set the instruction at an address
---@param addr integer Address of instruction
---@param insn Insn Instruction to set
function Mars:set(addr, insn)
    self.core[resolve(#self.core, addr)] = insn
end

---Compute the A-number/B-number of an A-operand/B-operand.
---@param pc integer Address of instruction
---@param operand ("A" | "B") Which number to compute
function Mars:compute_operand(pc, operand)
    local read_distance = self.options.read_distance or #self.core
    local write_distance = self.options.write_distance or #self.core

    local read_pc = pc
    local write_pc = pc

    ---@type nil | integer
    local post_inc_pc = nil

    local insn = self:fetch(pc)
    local mode = (operand == "A" and insn.aMode) or insn.bMode
    local value = (operand == "A" and insn.aNumber) or insn.bNumber
    -- print(string.format("operand=>%s, mode=>%s, value=>%d", operand, mode, value))

    if mode ~= types.Mode.Immediate then
        read_pc = clamp(#self.core, read_distance, read_pc, value)
        write_pc = clamp(#self.core, write_distance, write_pc, value)

        if mode ~= types.Mode.Direct then
            -- TODO: Add support for PreDecrementA
            if mode == types.Mode.PreDecrementB then
                local predec_insn = self:fetch(write_pc)
                predec_insn.bNumber = (predec_insn.bNumber + #self.core - 1) % #self.core
                -- TODO: Add support for PostIncrementA
            elseif mode == types.Mode.PostIncrementB then
                post_inc_pc = write_pc
            end

            read_pc = clamp(#self.core, read_distance, read_pc, self:fetch(read_pc).bNumber)
            write_pc = clamp(#self.core, write_distance, write_pc, self:fetch(write_pc).bNumber)
        end
    end

    -- TODO: Add support for PostIncrementA
    if post_inc_pc ~= nil then
        local post_inc_insn = self:fetch(post_inc_pc)
        post_inc_insn.bNumber = post_inc_insn.bNumber + 1
    end

    return {
        insn = self:fetch(read_pc),
        read_pc = read_pc,
        write_pc = write_pc
    }
end

return Mars
