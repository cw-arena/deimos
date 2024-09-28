local Mars = require "deimos.mars"
local parser = require "deimos.parser"
local types = require "deimos.types"

local function create_test_mars(...)
    local programs = {}
    for i = 1, select("#", ...) do
        local source = select(i, ...)
        if io.type(source) == "file" then
            local file = source
            source = file:read("*a")
            file:close()
        end
        assert.is_not_nil(source)
        local program = parser.parse_load_file(source)
        assert.is_not_nil(program)
        table.insert(programs, program)
    end
    local vm = Mars:new()
    vm:initialize(programs)
    return vm
end

describe("Mars", function()
    describe("compute_operand", function()
        local vm = Mars:new({
            core_size = 8000,
            read_distance = 8000,
            write_distance = 8000,
        })
        vm:initialize({
            parser.parse_load_file([[
                DAT.F #123, #456  ; PC=0
                ADD.AB $-1, $1    ; PC=1
                JMP.A @-1, @0     ; PC=2

                DAT.F #0, #1      ; PC=3
                MOV.A <-1, >1     ; PC=4
                CMP.A #0, #0      ; PC=5

                MOV.I $8000, $1   ; PC=6
                MOV.I $4001, $1   ; PC=7
            ]])
        })

        it("supports immediate mode", function()
            assert.are.same({
                insn = vm.core[1],
                read_pc = 0,
                write_pc = 0
            }, vm:compute_operand(0, "A"))

            assert.are.same({
                insn = vm.core[1],
                read_pc = 0,
                write_pc = 0
            }, vm:compute_operand(0, "B"))
        end)

        it("supports direct mode", function()
            assert.are.same({
                insn = vm.core[1],
                read_pc = 0,
                write_pc = 0,
            }, vm:compute_operand(1, "A"))
            assert.are.same({
                insn = vm.core[3],
                read_pc = 2,
                write_pc = 2,
            }, vm:compute_operand(1, "B"))
        end)

        it("supports indirect mode", function()
            assert.are.same({
                insn = vm.core[3],
                read_pc = 2,
                write_pc = 2,
            }, vm:compute_operand(2, "A"))
            assert.are.same({
                insn = vm.core[3],
                read_pc = 2,
                write_pc = 2,
            }, vm:compute_operand(2, "B"))
        end)

        it("supports B-number (pre/post)-increment modes", function()
            assert.are.same({
                insn = vm.core[4],
                read_pc = 3,
                write_pc = 3,
            }, vm:compute_operand(4, "A"))
            assert.is.equal("DAT.F #0, #0", types.formatInsn(vm.core[4]))
            assert.are.same({
                insn = vm.core[6],
                read_pc = 5,
                write_pc = 5,
            }, vm:compute_operand(4, "B"))
            assert.is.equal("CMP.A #0, #1", types.formatInsn(vm.core[6]))
        end)

        it("respects read limits", function()
            assert.are.same({
                insn = vm.core[7],
                read_pc = 6,
                write_pc = 6,
            }, vm:compute_operand(6, "A"))
            assert.are.same({
                insn = vm.core[8 - 4000 + #vm.core + 1],
                read_pc = 8 - 4000 + #vm.core,
                write_pc = 8 - 4000 + #vm.core,
            }, vm:compute_operand(7, "A"))
        end)
    end)

    describe("execute_cycle", function()
        describe("DIV", function()
            it("kills warrior on divide by zero", function()
                local vm = create_test_mars("DIV.AB #0, #5")
                vm:execute_cycle()

                local warrior = vm.warriors_by_id["1"]
                assert.is_nil(warrior)
            end)
        end)

        describe("MOD", function()
            it("kills warrior on divide by zero", function()
                local vm = create_test_mars("MOD.AB #0, #5")
                vm:execute_cycle()

                local warrior = vm.warriors_by_id["1"]
                assert.is_nil(warrior)
            end)
        end)

        describe("JMP", function()
            it("jumps to A-pointer", function()
                local vm = create_test_mars("JMP.A $123, #0")
                vm:execute_cycle()

                local warrior = vm.warriors_by_id["1"]
                assert.is_not_nil(warrior)
                assert.are.same({ id = 0, pc = 123 }, warrior.tasks:peek())
            end)
        end)
    end)

    it("can execute a dwarf correctly", function()
        local file = assert(io.open("./warriors/dwarf.red", "r"))
        local vm = create_test_mars(file)

        assert.is_not_nil(vm.warriors_by_id["1"])
        local warrior = vm.warriors_by_id["1"]

        assert.is.equal("1", warrior.id)
        assert.is.equal(1, warrior.next_task_id)
        assert.is.equal(1, warrior.tasks:length())
        assert.are.same({ id = 0, pc = 1 }, warrior.tasks:peek())

        vm:execute_cycle()
        assert.are.same({ id = 0, pc = 2 }, warrior.tasks:peek())
        assert.are.same(parser.parse_insn("DAT.F #0, #4"), vm.core[1])

        vm:execute_cycle()
        assert.are.same({ id = 0, pc = 3 }, warrior.tasks:peek())
        assert.are.same(parser.parse_insn("DAT.F #0, #4"), vm.core[5])

        vm:execute_cycle()
        assert.are.same({ id = 0, pc = 1 }, warrior.tasks:peek())
    end)

    describe("hooks", function()
        it("calls hooks when executing warrior", function()
            local file = assert(io.open("./warriors/dwarf.red", "r"))
            local vm = create_test_mars(file)

            local events = { "warrior.begin", "warrior.insn", "warrior.task_update" }
            local called_events = {}

            vm:install_back(events, function(event, data)
                local cycle = 0
                local warrior = vm.warriors_by_id["1"]
                local pc = 1
                local insn = parser.parse_insn("ADD.AB #4, $-1")
                local a_operand = {
                    insn = insn,
                    read_pc = 1,
                    write_pc = 1
                }
                local b_operand = {
                    insn = parser.parse_insn("DAT.F #0, #0"),
                    read_pc = 0,
                    write_pc = 0,
                }

                if event == "warrior.begin" then
                    assert.are.same(
                        {
                            cycle = cycle,
                            warrior = warrior,
                            pc = pc,
                            insn = insn,
                        },
                        data
                    )
                elseif event == "warrior.insn" then
                    assert.are.same(
                        {
                            cycle = cycle,
                            warrior = warrior,
                            pc = pc,
                            insn = insn,
                            a_operand = a_operand,
                            b_operand = b_operand,
                        },
                        data
                    )
                elseif event == "warrior.task_update" then
                    assert.are.same(
                        {
                            cycle = cycle,
                            warrior = warrior,
                            pc = pc,
                            insn = insn,
                            task_update = { next_pc = 2 }
                        },
                        data
                    )
                end
                assert.is_nil(called_events[event])
                called_events[event] = event
                return types.HookAction.RESUME
            end)

            vm:execute_cycle()

            -- NB: Ensure every requested event was received
            for _, event in ipairs(events) do
                assert.is.equal(event, called_events[event])
            end

            -- NB: Ensure every received event was requested
            for _, called_event in pairs(called_events) do
                local found = false
                for _, event in ipairs(events) do
                    found = found or called_event == event
                end
                assert.is_true(found)
            end
        end)

        it("calls hooks in correct order", function()
            local vm = create_test_mars("MOV.I $0, $1")
            local calls = {}
            for i = 1, 5 do
                vm:install_back({ "warrior.begin" }, function()
                    table.insert(calls, i)
                    return types.HookAction.RESUME
                end)
            end
            vm:execute_cycle()
            assert.are.same({ 1, 2, 3, 4, 5 }, calls)
        end)

        it("returns control when hook pauses execution", function()
            local vm = create_test_mars("MOV.I $0, $1")
            vm:install_back({ "warrior.begin" }, function()
                return types.HookAction.PAUSE
            end)

            local co = coroutine.create(function()
                vm:execute_cycle()
            end)
            coroutine.resume(co)
            assert.is.equal("suspended", coroutine.status(co))

            coroutine.resume(co)
            assert.is.equal("dead", coroutine.status(co))
        end)

        it("invokes warrior.died hooks when warrior dies", function()
            local vm = create_test_mars("DAT.F #0, #0")
            local called = false
            vm:install_back({ "warrior.died" }, function(event, data)
                called = true
                assert.is.equal("warrior.died", event)
                assert.are.same({
                    cycle = 0,
                    pc = 0,
                    warrior = vm.warriors_by_id["1"],
                    insn = parser.parse_insn("DAT.F #0, #0"),
                }, data)
                return types.HookAction.RESUME
            end)
            vm:execute_cycle()
            assert.is_true(called)
        end)
    end)
end)
