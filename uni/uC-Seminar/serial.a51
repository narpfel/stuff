$NOLIST


LF EQU 0AH
CR EQU 0DH


; Write the byte in `A` to the UART.
WRITECHAR:
    JNB TI, WRITECHAR
    MOV SBUF, A
    CLR TI
    RET


; Write a line feed (i. e. CR-LF) to the UART.
WRITE_LINE_END:
    MOV A, #CR
    CALL WRITECHAR
    MOV A, #LF
    CALL WRITECHAR
    RET


; Write the `0` terminated string starting at `@R0` to the UART.
; If `F0` is set, this function automatically sends a line feed (i. e. CR-LF)
; after the string has been written.
WRITESTRING:
    MOV A, @R0
    INC R0
    JZ _WRITESTRING_END
    CALL WRITECHAR
    JMP WRITESTRING
_WRITESTRING_END:
    JNB F0, _WRITESTRING_RET
    CALL WRITE_LINE_END
_WRITESTRING_RET:
    RET


; Write the `0` terminated string starting at `DPTR` to the UART.
; The string is read from the code memory.
WRITEFIXSTR:
    CLR     A
    MOVC    A,@A+DPTR
    INC     DPTR
    JZ      _WRITEFIXSTR_RET
    CALL   WRITECHAR
    JMP    WRITEFIXSTR
_WRITEFIXSTR_RET:
    RET


; Read maximal ``A`` bytes of input, storing them into ``@R1``.
READ_INPUT:
    MOV R0, A
    MOV R2, #0
_READ_INPUT_LOOP:
    CALL   READ_BYTE
    MOV    R2, A
    SUBB   A, #13
    JZ     _READ_INPUT_RET
    MOV    A, R2
    MOV    @R1, A
    INC    R1
    DJNZ   R0, _READ_INPUT_LOOP
_READ_INPUT_RET:
    MOV    @R1, #0
    RET


; Read one byte from the serail interface, storing it in `A`.
; Additionally, the read byte is inverted and then written to `P1`.
READ_BYTE:
    JNB RI, READ_BYTE
    MOV A, SBUF
    CLR RI
    CPL A
    MOV P1, A
    CPL A
    RET


$LIST
