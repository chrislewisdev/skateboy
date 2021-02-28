INCLUDE "hardware.inc"
INCLUDE "defines.inc"

SECTION "ROM Title", ROM0[$0134]
  DB "Skateboy"

SECTION "Nintendo Logo", ROM0[$0104]
  NINTENDO_LOGO

SECTION "Entrypoint", ROM0[$0100]
  nop
  jp Startup

SECTION "Game code", ROM0[$0150]
Startup:
  call InitState
  call InitGraphics
GameLoop:
  call WaitForNextVerticalBlank
  call AnimateHead
  call AnimateLegs
  call ScrollRight
  call ReadInput
  call CheckOnGround
  jr nz, .notOnGround
  .onGround
    ld a, 0
    ld [airTimer], a
    call CheckJumpInput
    call CheckLanding
    jr .endOfGroundCheck
  .notOnGround
    ld a, [airTimer]
    inc a
    ld [airTimer], a
    call DecayVelocity
  .endOfGroundCheck
  call EvaluateVelocity
  call UpdateSprites
  ld a, [frameCounter]
  inc a
  ld [frameCounter], a
  jp GameLoop

InitState:
  ld a, SIGNED_BASELINE
  ld [jumpVelocity], a
  ld a, 113
  ld [verticalPosition], a

ScrollRight:
  ld a, [rSCX]
  add a, 2
  ld [rSCX], a
  ret

CheckJumpInput:
  ld a, [previousInput]
  and BTN_A
  ret nz
    ld a, [input]
    and BTN_A
    ret z
      ld a, SIGNED_BASELINE + 3
      ld [jumpVelocity], a
  ret

; To be called when the player is touching the ground
; Zeroes their vertical velocity only if falling
CheckLanding:
  ld a, [jumpVelocity]
  cp SIGNED_BASELINE
  ret nc
  ld a, SIGNED_BASELINE
  ld [jumpVelocity], a
  ; TODO find a better way to pass over the overlapping pixel count from CheckOnGround
  ; Adjust the player to rest exactly on top of the ground tile
  ld a, [verticalPosition]
  sub a, d
  ld [verticalPosition], a
  ret

CheckOnGround:
  ; What vertical row is the player on?
  ld a, [verticalPosition]
  sub 1
  ld b, 8
  call DivideAB
  add a, 8
  ld d, a   ; store remainder in d (for use in CheckLanding)
  ld hl, _SCRN0
  ld a, c
  ld bc, 32
  or a
  jr z, .rowSeekComplete
  .untilRowSeekComplete
    add hl, bc  ; one row
    dec a
    jr nz, .untilRowSeekComplete
  .rowSeekComplete
  ; What horizontal column is the player on?
  ld a, [rSCX]
  add a, FIXED_X_POSITION
  ld b, 8
  call DivideAB
  ; the divide result is in c, set b to 0 so bc = c
  ld b, 0
  add hl, bc
  ld a, [hl]
  cp 17
  jr nz, .notOnGround
  .onGround
    ld a, 1
    ret
  .notOnGround
    ld a, 0
    ret

DecayVelocity:
  ; only do every 4 frames once in air
  ld a, [airTimer]
  and 3 ; modulo 4
  ret nz
  ld a, [jumpVelocity]
  dec a
  cp SIGNED_BASELINE - 5
  ret c
  ld [jumpVelocity], a
  ret

EvaluateVelocity:
  ld a, [jumpVelocity]
  ld d, a
  cp SIGNED_BASELINE
  jr c, .isFalling
  .isJumping
    sub a, SIGNED_BASELINE
    ld b, a
    ld a, [verticalPosition]
    sub a, b
    ld [verticalPosition], a
    jr .endOfJumpLogic
  .isFalling
    ld b, a
    ld a, SIGNED_BASELINE
    sub a, b
    ld b, a
    ld a, [verticalPosition]
    add a, b
    ld [verticalPosition], a
  .endOfJumpLogic
  ret
