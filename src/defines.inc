; Variables
frameCounter        EQU _RAM
input               EQU _RAM+1
previousInput       EQU _RAM+2
jumpVelocity        EQU _RAM+3
verticalPosition    EQU _RAM+4
airTimer            EQU _RAM+5
animationFlags      EQU _RAM+6
movementFlags       EQU _RAM+7
grindGraceTimer     EQU _RAM+8
loadTriggerCounter  EQU _RAM+9
mapLoadIndex        EQU _RAM+10
mapInsertIndex      EQU _RAM+11
mapProgressIndex    EQU _RAM+12

; Input Constants
BTN_DOWN      EQU %10000000
BTN_UP        EQU %01000000
BTN_LEFT      EQU %00100000
BTN_RIGHT     EQU %00010000
BTN_START     EQU %00001000
BTN_SELECT    EQU %00000100
BTN_B         EQU %00000010
BTN_A         EQU %00000001

FIXED_X_POSITION  EQU 20
SIGNED_BASELINE   EQU 127

GRIND_FLAG        EQU %00000001
GROUND_FLAG       EQU %00000010