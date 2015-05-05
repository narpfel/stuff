$NOLIST

; Sleep for approximately `R0` milliseconds.
SLEEP_MS:
    push ACC
    push AR1
    push AR2
    mov A, R0
    jz _SLEEP_MS_RET
    MILLISECOND_LOOP:
        mov R1, #3
        OUTER_LOOP:
            mov R2, #153
            INNER_LOOP:
                nop
                nop
                djnz R2, INNER_LOOP
            djnz R1, OUTER_LOOP
        djnz R0, MILLISECOND_LOOP
_SLEEP_MS_RET:
    pop AR2
    pop AR1
    pop ACC
    ret

$LIST
