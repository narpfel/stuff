$NOLIST

; Convert one byte (given in ``R2``) to a 3-digit string in decimal
; representation (starting at ``@R0``). Uses ``R1``, ``R3`` and ``R4``.
BIN_TO_DEC:
        MOV R1, #3
        MOV A, R2
        MOV R4, A
        MOV R3, #100
_BIN_TO_DEC_LOOP:
        MOV B, R3
        MOV A, R4
        DIV AB
        ADD A, #30H
        MOV @R0, A
        INC R0
        MOV R4, B
        MOV A, R3
        MOV B, #10
        DIV AB
        MOV R3, A
        DJNZ R1, _BIN_TO_DEC_LOOP
        RET

$LIST
