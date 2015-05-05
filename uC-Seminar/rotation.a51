$NOLIST


; Rotate `A` for `N` bits to the right. `N` may be a register or a direct
; address.
; If `N` contains the value `0`, this is essentially a no-op that costs
; 24 cycles as A is rotated eight times.
ROTATE_RIGHT MACRO N
LOCAL _ROTATE_RIGHT
_ROTATE_RIGHT:
    RR A
    DJNZ N, _ROTATE_RIGHT
ENDM


$LIST
