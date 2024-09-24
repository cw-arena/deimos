local load_file = require "deimos.parser.load_file"

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
