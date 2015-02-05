;
$DATE (05.02.2015)
$TITLE (PHOTO_ENCODER)
$PAGELENGTH(56)
$PAGEWIDTH(150)
$DEBUG
$XREF
$NOLIST
$NOMOD51
$INCLUDE(89s8252.mcu)
$LIST



NAME      PHOTO_ENCODER

CODEMEM EQU 8000H

ENCODER_LEFT EQU P1.1
ENCODER_RIGHT EQU P1.0
SET_ZERO_BUTTON EQU P1.4

PHOTO_SENSOR EQU 2
ENCODER EQU 0

PORT_EXPANDER_ADDRESS EQU 00B


DSEG AT 20h
OLD_STATE_ENCODER: DS 1
;;OLD_STATE_PHOTO_SENSOR: DS 1


DSEG AT 30h
CURRENT_STATE_ENCODER: DS 1
;;CURRENT_STATE_PHOTO_SENSOR: DS 1
ENCODER_COUNTER: DS 1
;;PHOTO_SENSOR_COUNTER: DS 1

;;CURRENT_CURRENT_STATE: DS 1
;;CURRENT_OLD_STATE: DS 1
;;CURRENT_COUNTER: DS 1

OUTPUT_STRING: DS 4
UNIT: DS 2


CSEG AT CODEMEM

        LJMP START


ORG     CODEMEM+30H

INIT_SERIAL:
        MOV     A,#244          ; BR-Count (s.o.)
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

$INCLUDE(bin2dec.a51)

$INCLUDE(I2C.a51)

$INCLUDE(rotation.a51)

; Compute the logical xor of `left` and `right` in 3 cycles.
; Returns the result in `C`
XOR_BITS MACRO left, right
LOCAL OVER
    ; `left` xor `right`
    MOV C, left
    JNB right, OVER
    CPL C
OVER:
    ; Finished.
ENDM


; Read the current state of either `PHOTO_SENSOR` or `ENCODER` (given in `R4`).
; The current state is returned in the two LSBs of `A`.
; Uses registers 0 through 4 and some bytes on the stack.
READ_STATE:
    MOV R2, #PORT_EXPANDER_ADDRESS
    MOV R1, #1
    MOV R0, #AR3
    CALL PE0Read
    MOV A, R3
    ;MOV P1, A
    ROTATE_RIGHT R4
    ANL A, #11b
    RET


START:
    MOV     SP, #STACKSTART
    CALL    INIT_SERIAL

    MOV     ENCODER_COUNTER, #0
    MOV CURRENT_STATE_ENCODER, #0

LOOP:
    MOV UNIT, #(HIGH MILLIMETERS)
    MOV UNIT + 1, #(LOW MILLIMETERS)

    ;;MOV CURRENT_COUNTER, #CURRENT_STATE_ENCODER
    ;;MOV CURRENT_CURRENT_STATE, #CURRENT_STATE_ENCODER
    ;;MOV CURRENT_

    MOV OLD_STATE_ENCODER, CURRENT_STATE_ENCODER
    MOV R4, #ENCODER
    CALL READ_STATE

    MOV CURRENT_STATE_ENCODER, A
    CJNE A, OLD_STATE_ENCODER, UNEQUAL
    JNB SET_ZERO_BUTTON, SET_ZERO

    JMP LOOP
UNEQUAL:
    RL A
    RL A
    ADD A, OLD_STATE_ENCODER
    JNB P, ERROR ; Invalid state

    XOR_BITS ACC.2, OLD_STATE_ENCODER.1

    JC DECREASE
INCREASE:
    INC ENCODER_COUNTER
    JMP PRINT_STATE
DECREASE:
    DEC ENCODER_COUNTER
    JMP PRINT_STATE

ERROR:
    JMP LOOP

SET_ZERO:
    MOV A, ENCODER_COUNTER
    JZ LOOP
    MOV ENCODER_COUNTER, #0
    JMP PRINT_STATE

PRINT_STATE:
    MOV R0, #OUTPUT_STRING
    MOV R2, ENCODER_COUNTER
    CALL BIN_TO_DEC
    MOV R0, #OUTPUT_STRING
    CLR F0
    CALL WRITESTRING
    MOV DP0H, UNIT
    MOV DP0L, UNIT + 1
    CALL WRITEFIXSTR
    JMP LOOP

MILLIMETERS: DB " mm", 13, 10
NO_UNIT: DB 13, 10

DSEG

STACKSTART: DS 1

END
