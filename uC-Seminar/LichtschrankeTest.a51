;
$DATE (19.12.2014)
$TITLE (LichtschrankeTest)
$PAGELENGTH(56)
$PAGEWIDTH(150)
$DEBUG
$XREF
$NOLIST
$NOMOD51
$INCLUDE(89s8252.mcu)
$LIST
;


NAME      TEST_LICHTSCHRANKE

CODEMEM EQU 8000H

ENCODER_LEFT EQU P1.1
ENCODER_RIGHT EQU P1.0

DSEG AT 30h

CURRENT_STATE: DS 1
OLD_STATE: DS 1
ENCODER: DS 1
;;OLD_PRINTOUT: DS 1
ENCODER_STRING: DS 4

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


START:
        MOV     SP, #STACKSTART
        CALL    INIT_SERIAL

        MOV     ENCODER, #0
        MOV CURRENT_STATE, #0
        ;;MOV OLD_PRINTOUT, #0

LOOP:
        MOV     OLD_STATE, CURRENT_STATE
        MOV     A, P1
        ANL     A, #11b
        ;RR A
        ;RR A
        MOV     CURRENT_STATE, A
        CJNE A, OLD_STATE, UNEQUAL
        JNB P1.4, SET_ZERO
        JMP LOOP
UNEQUAL:
        RL A
        RL A
        ADD A, OLD_STATE
        RL A

        ;;RR A
        ;MOV R0, #ENCODER_STRING
        ;MOV R2, A
        ;CALL BIN_TO_DEC
        ;MOV R0, #ENCODER_STRING
        ;CALL WRITESTRING
        ;;RL A

        MOV DPTR, #JUMP_TABLE
        JMP @A + DPTR
JUMP_TABLE:
        ; 0 NOP
        SJMP ERROR

        ; 1
        SJMP DECREASE

        ; 2
        SJMP INCREASE

        ; 3
        SJMP ERROR

        ; 4 LOOP
        SJMP INCREASE

        ; 5 NOP
        SJMP ERROR

        ; 6
        SJMP ERROR

        ; 7 LOOP
        SJMP DECREASE

        ; 8 LOOP
        SJMP DECREASE

        ; 9
        SJMP ERROR

        ; 10 NOP
        SJMP ERROR

        ; 11 LOOP
        SJMP INCREASE

        ; 12
        SJMP ERROR

        ; 13
        SJMP INCREASE

        ; 14
        SJMP DECREASE

        ; 15 not used.
        SJMP ERROR

INCREASE:
        INC ENCODER
        JMP PRINT_STATE

DECREASE:
        DEC ENCODER
        JMP PRINT_STATE

ERROR:
        JMP LOOP

SET_ZERO:
         MOV A, ENCODER
         JZ LOOP
         MOV ENCODER, #0
         JMP PRINT_STATE

PRINT_STATE:
        ;;CLR C
        ;;RRC A
        ;;CJNE A, OLD_PRINTOUT, PRINT_STATE_CONTINUE
        ;;JMP LOOP
;;PRINT_STATE_CONTINUE:
        ;;MOV OLD_PRINTOUT, A
        MOV R0, #ENCODER_STRING
        MOV R2, ENCODER
        ;MOV A, R2
        ;CLR C
        ;RRC A
        ;MOV R2, A
        CALL BIN_TO_DEC
        MOV R0, #ENCODER_STRING
        CALL WRITESTRING
        JMP LOOP



DSEG

STACKSTART: DS 1

END
