local parser = require "deimos.parser.load_file"

local program = parser.parse([[
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
MOV.AB  #0, @-2    ; Bombs target instruction.
JMP.A   $-2, #0    ; Loops back two instructions.
]])

local function dump(o)
    if type(o) == 'table' then
        local s = '{ '
        for k, v in pairs(o) do
            if type(k) ~= 'number' then k = '"' .. k .. '"' end
            s = s .. '[' .. k .. '] = ' .. dump(v) .. ','
        end
        return s .. '} '
    else
        return tostring(o)
    end
end

print(dump(program))

return {
    parser = parser,
}
