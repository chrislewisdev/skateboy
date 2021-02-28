; Variables
frameCounter        EQU _RAM
input               EQU _RAM+1
previousInput       EQU _RAM+2
jumpVelocity        EQU _RAM+3
verticalPosition    EQU _RAM+4
airTimer            EQU _RAM+5

; Input Constants
BTN_DOWN      EQU %10000000
BTN_UP        EQU %01000000
BTN_LEFT      EQU %00100000
BTN_RIGHT     EQU %00010000
BTN_START     EQU %00001000
BTN_SELECT    EQU %00000100
BTN_B         EQU %00000010
BTN_A         EQU %00000001

; Sprite references
SPR0_Y      EQU _OAMRAM
SPR0_X      EQU _OAMRAM+1
SPR0_ID     EQU _OAMRAM+2
SPR1_Y      EQU _OAMRAM+4
SPR1_X      EQU _OAMRAM+5
SPR1_ID     EQU _OAMRAM+6
SPR2_Y      EQU _OAMRAM+8
SPR2_X      EQU _OAMRAM+9
SPR2_ID     EQU _OAMRAM+10
SPR3_Y      EQU _OAMRAM+12
SPR3_X      EQU _OAMRAM+13
SPR3_ID     EQU _OAMRAM+14

FIXED_X_POSITION  EQU 40
SIGNED_BASELINE   EQU 127