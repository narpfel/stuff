CSEG at 8000H

jmp LOOP

$INCLUDE(sleep.a51)

LOOP:
        mov P1, A
        cpl A
        REPT 4
            mov R0, #250
            call SLEEP_MS
        ENDM
        jmp LOOP

END
