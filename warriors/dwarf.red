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