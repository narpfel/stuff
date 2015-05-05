$TITLE (NumberInput.a51)
$PAGELENGTH(56)
$PAGEWIDTH(150)
$DEBUG
$XREF
$NOLIST
$NOMOD51
$INCLUDE(89s8252.mcu)
$LIST


      NAME      NumberInput



CODEMEM EQU     8000H

LED     EQU     P1.7    ; Portanschluss für LED


EOT     EQU     04H
INPUT_LENGTH EQU 50


        DSEG    AT      30H

INPUT:  DS INPUT_LENGTH
RESULT: DS 1


        CSEG    AT      CODEMEM

        LJMP    Start


;********************************************************************************************************
; Baudrateneinstellungen:
; SMOD = 1 ==> TH1 = 256 - (2 * f/Hz) / (384 * BR)

; 22,1184 MHz -   2400 : 208     24 MHz - 2400 : 204        12 MHz - 2400 : 230
;             -   4800 : 232            - 4800 : 230               - 4800 : 243
;             -   9600 : 244            - 9600 : 243
;             -  19200 : 250
;             -  38400 : 253
;             -  57600 : 254
;             - 115200 : 255

;********************************************************************************************************
; RS232 initalisieren

        ORG     CODEMEM+30H

Init:   MOV     A,#244          ; BR-Count (s.o.)
        MOV     TH1,A           ; load value

        MOV     A,TMOD
        ANL     A,#0FH
        ADD     A,#20H
        MOV     TMOD,A          ; timer 1 mode 2 (8 bit, auto-reload)
        CLR     SM0             ; serial mode 1 (8-bit)
        SETB    SM1
        SETB    TR1             ; start timer
        MOV     A,PCON
        ORL     A,#80H
        MOV     PCON,A          ; SMOD=1 (Baudrate x 2)
        SETB    REN             ; Enable receiver
        SETB    TI              ; set TI for transmit buffer empty
        CLR     RI              ; clear SI for receive interrupt
        RET

$INCLUDE(serial.a51)

; Clear ``A`` bytes of internal memory, starting at ``@R1``.
CLEARMEM:
        MOV R0, A
CLEARMEM_LOOP:
        MOV @R1, #0
        INC R1
        DJNZ R0, CLEARMEM_LOOP
        RET

; Count the number of bytes that are not ``#0``, starting at ``@R1``, returning
; the result in ``R0``.
COUNT_NOT_NULL:
        MOV R0, 0
COUNT_NOT_NULL_LOOP:
        CJNE @R1, #0, COUNT_NOT_NULL_RET
        INC A
        INC R1
        JMP COUNT_NOT_NULL_LOOP
COUNT_NOT_NULL_RET:
        RET


; Convert ``R2`` ASCII encoded decimal bytes (starting at ``@R1``) to binary,
; returning them in ``R0``.
DEC2BIN:
        MOV     R0, #0
        MOV     R4, #0
        MOV     A, R2
        JZ      DEC2BIN_RET
        MOV     A, R1
        ADD     A, R2
        DEC     A
        MOV     R1, A
DEC2BIN_LOOP:
        MOV     A, @R1
        SUBB    A, #30H

        MOV     B, A
        MOV     A, R4
        MOV     R3, A
        JNZ     POW
        MOV     A, B
NEXT:   ADD     A, R0
        MOV     R0, A
        DEC     R1
        INC     R4
        DJNZ    R2, DEC2BIN_LOOP
DEC2BIN_RET:
        RET



POW:
        MOV     A, B
POW_LOOP:
        MOV     B, #10
        MUL     AB
        DJNZ    R3, POW_LOOP
        SJMP    NEXT


Start:  MOV     SP,#STACKSTART
        CALL    INIT
        MOV     DPTR,#TEXT
        CALL    WRITEFIXSTR
        MOV     INPUT + INPUT_LENGTH, #0
LOOP:   MOV     A, #INPUT_LENGTH
        MOV     R1, #INPUT
        CALL    READ_INPUT
        MOV     A, R1
        SUBB    A, #INPUT

        MOV     R2, A
        MOV     R1, #INPUT
        CALL    DEC2BIN
        MOV     A, R0
        CPL     A
        MOV     P1, A

        MOV     INPUT + INPUT_LENGTH, #0
        MOV     R0, #INPUT
        SETB    F0
        CALL    WRITESTRING

        SJMP    LOOP



TEXT:   DB      'Hallo, hier ist der Mikrocontroller!',13,10,'Tippen Sie ein paar Zeichen: ',0

        DSEG

STACKSTART:
        DS      1       ; stack: rest of data memory

END
