local insn   = require "deimos.data.insn"
local parser = require "deimos.parser"

describe("parse_instruction", function()
    it("can parse all opcodes", function()
        for _, value in pairs(insn.Opcode) do
            local source = string.format("%s.F #0, #0", value)
            assert.are.same(
                {
                    opcode = value,
                    modifier = insn.Modifier.F,
                    a_mode = insn.Mode.Immediate,
                    a_number = 0,
                    b_mode = insn.Mode.Immediate,
                    b_number = 0
                },
                parser.parse_insn(source)
            )
        end
    end)

    it("can parse all modes", function()
        for _, value in pairs(insn.Mode) do
            local source = string.format("MOV.I %s0, $1", value)
            assert.are.same(
                {
                    opcode = insn.Opcode.MOV,
                    modifier = insn.Modifier.I,
                    a_mode = value,
                    a_number = 0,
                    b_mode = insn.Mode.Direct,
                    b_number = 1
                },
                parser.parse_insn(source)
            )
        end
    end)

    it("can parse all modifiers", function()
        for _, value in pairs(insn.Modifier) do
            local source = string.format("ADD.%s #1, $2", value)
            assert.are.same(
                {
                    opcode = insn.Opcode.ADD,
                    modifier = value,
                    a_mode = insn.Mode.Immediate,
                    a_number = 1,
                    b_mode = insn.Mode.Direct,
                    b_number = 2
                },
                parser.parse_insn(source)
            )
        end
    end)

    it("can parse signed operands", function()
        assert.are.same(
            {
                opcode = insn.Opcode.MOV,
                modifier = insn.Modifier.I,
                a_mode = insn.Mode.Direct,
                a_number = 2,
                b_mode = insn.Mode.Indirect,
                b_number = -2,
            },
            parser.parse_insn("MOV.I $+2, @-2")
        )
    end)

    it("rejects parse with trailing garbage", function()
        assert.is_nil(parser.parse_insn("MOV.I $0, $1 extra garbage"))
    end)
end)

describe("parse_load_file", function()
    it("can parse a complete load file", function()
        local dwarf_file = assert(io.open("./warriors/dwarf.red", "r"))
        local dwarf_code = dwarf_file:read("*a")
        dwarf_file:close()

        assert.are.same(
            {
                metadata = {},
                insns = {
                    { org = 1 },
                    { opcode = "DAT", modifier = "F",  a_mode = "#", a_number = 0,  b_mode = "#", b_number = 0 },
                    { opcode = "ADD", modifier = "AB", a_mode = "#", a_number = 4,  b_mode = "$", b_number = -1 },
                    { opcode = "MOV", modifier = "I",  a_mode = "$", a_number = -2, b_mode = "@", b_number = -2 },
                    { opcode = "JMP", modifier = "A",  a_mode = "$", a_number = -2, b_mode = "#", b_number = 0 }
                }
            },
            parser.parse_load_file(dwarf_code)
        )
    end)
end)
