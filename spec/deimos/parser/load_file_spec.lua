local load_file = require "deimos.parser.load_file"
local types     = require "deimos.types"

describe("parse_instruction", function()
    it("can parse all opcodes", function()
        for _, value in pairs(types.Opcode) do
            local insn = string.format("%s.F #0, #0", value)
            assert.are.same(
                {
                    opcode = value,
                    modifier = types.Modifier.F,
                    aMode = types.Mode.Immediate,
                    aNumber = 0,
                    bMode = types.Mode.Immediate,
                    bNumber = 0
                },
                load_file.parse_insn(insn)
            )
        end
    end)

    it("can parse all modes", function()
        for _, value in pairs(types.Mode) do
            local insn = string.format("MOV.I %s0, $1", value)
            assert.are.same(
                {
                    opcode = types.Opcode.MOV,
                    modifier = types.Modifier.I,
                    aMode = value,
                    aNumber = 0,
                    bMode = types.Mode.Direct,
                    bNumber = 1
                },
                load_file.parse_insn(insn)
            )
        end
    end)

    it("can parse all modifiers", function()
        for _, value in pairs(types.Modifier) do
            local insn = string.format("ADD.%s #1, $2", value)
            assert.are.same(
                {
                    opcode = types.Opcode.ADD,
                    modifier = value,
                    aMode = types.Mode.Immediate,
                    aNumber = 1,
                    bMode = types.Mode.Direct,
                    bNumber = 2
                },
                load_file.parse_insn(insn)
            )
        end
    end)

    it("can parse signed operands", function()
        assert.are.same(
            {
                opcode = types.Opcode.MOV,
                modifier = types.Modifier.I,
                aMode = types.Mode.Direct,
                aNumber = 2,
                bMode = types.Mode.Indirect,
                bNumber = -2,
            },
            load_file.parse_insn("MOV.I $+2, @-2")
        )
    end)

    it("can parse trailing comments", function()
        assert.are.same(
            {
                opcode = types.Opcode.MOV,
                modifier = types.Modifier.I,
                aMode = types.Mode.Direct,
                aNumber = 0,
                bMode = types.Mode.Direct,
                bNumber = 1
            },
            load_file.parse_insn("MOV.I $0, $1 ; this is a test comment")
        )
    end)

    it("rejects parse with trailing garbage", function()
        assert.is_nil(load_file.parse_insn("MOV.I $0, $1 extra garbage"))
    end)
end)

describe("parse_load_file", function()
    it("can parse a complete load file", function()
        assert.are.same(
            {
                { org = 1 },
                { opcode = "DAT", modifier = "F",  aMode = "#", aNumber = 0,  bMode = "#", bNumber = 0 },
                { opcode = "ADD", modifier = "AB", aMode = "#", aNumber = 4,  bMode = "$", bNumber = -1 },
                { opcode = "MOV", modifier = "I",  aMode = "$", aNumber = -2, bMode = "@", bNumber = -2 },
                { opcode = "JMP", modifier = "A",  aMode = "$", aNumber = -2, bMode = "#", bNumber = 0 }
            },
            load_file.parse_load_file([[
                ;redcode

                ;name          Dwarf
                ;author        A. K. Dewdney
                ;version       94.1
                ;date          April 29, 1993

                ;strategy      Bombs every fourth instruction.

                ORG     1          ; Indicates execution begins with the second
                                   ; instruction (ORG is not actually loaded, and is
                                   ; therefore not counted as an instruction).

                DAT.F   #0, #0     ; Pointer to target instruction.
                ADD.AB  #4, $-1    ; Increments pointer by step.
                MOV.I  $-2, @-2    ; Bombs target instruction.
                JMP.A  $-2, #0     ; Loops back two instructions.
            ]])
        )
    end)
end)
