local Mars = require "deimos.vm.mars"
local load_file = require "deimos.parser.load_file"
local types = require "deimos.types"

describe("Mars", function()
    describe("compute_operand", function()
        local vm = Mars:new()
        vm:initialize({
            load_file.parse_load_file([[
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
end)
