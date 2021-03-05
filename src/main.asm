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
  call DetermineAnimationFrames
  call UpdateSprites
  call ScrollRight
  call ReadInput
  ; update b hold timer (for grace window)
  ld a, [input]
  and BTN_B
  jr z, .clearHoldTimer
  .incrementHoldTimer
    ld hl, grindGraceTimer
    inc [hl]
    jr .endHoldCheck
  .clearHoldTimer
    ld a, 0
    ld [grindGraceTimer], a
  .endHoldCheck
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
    call CheckGrindInput
    call DecayVelocity
  .endOfGroundCheck
  call EvaluateVelocity
  ld a, [frameCounter]
  inc a
  ld [frameCounter], a
  jp GameLoop

InitState:
  ld a, SIGNED_BASELINE
  ld [jumpVelocity], a
  ld a, 113
  ld [verticalPosition], a
  ld a, 0
  ld [movementFlags], a
  ld [grindGraceTimer], a

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

CheckGrindInput:
  ld a, [movementFlags]
  and GRIND_FLAG
  jr nz, .continueGrind
  .initiateGrind
    ld a, [input]
    and BTN_B
    ret z
    ; Allow grace period between pressing B and initiating the grind 
    ld a, [grindGraceTimer]
    cp 30
    ret nc
    inc a
    ld [grindGraceTimer], a
    ; are we on a grindable surface?
    ld a, [verticalPosition]
    add a, 3
    ld d, a
    ld a, [rSCX]
    add a, FIXED_X_POSITION + 4
    ld e, a
    call ResolveTileAddress
    ld a, [hl]
    cp 1
    ret c
    cp 5
    ret nc
    ; We are on a grindable surface and B has been pressed.
    ld a, d
    and a, 7  ; modulo 8
    ld b, a
    ld a, [verticalPosition]
    sub a, b
    add a, 4
    ld [verticalPosition], a
    ld a, [movementFlags]
    or GRIND_FLAG
    ld [movementFlags], a
    ld a, SIGNED_BASELINE
    ld [jumpVelocity], a
    ret
  .continueGrind
    ld a, [input]
    and BTN_B
    jr z, .exitGrindWithOllie
      ld a, [verticalPosition]
      add a, 3
      ld d, a
      ld a, [rSCX]
      add a, FIXED_X_POSITION - 5
      ld e, a
      call ResolveTileAddress
      ld a, [hl]
      cp 2
      jr c, .exitGrind
      cp 5
      jr nc, .exitGrind
      ret
  .exitGrindWithOllie
  ld a, SIGNED_BASELINE + 3
  ld [jumpVelocity], a
  ld a, 1
  ld [airTimer], a
  .exitGrind
  ld a, [movementFlags]
  ld b, a
  ld a, GRIND_FLAG
  cpl
  and a, b
  ld [movementFlags], a
  ret

; To be called when the player is touching the ground
; Zeroes their vertical velocity only if falling
CheckLanding:
  ld a, [jumpVelocity]
  cp SIGNED_BASELINE
  ret nc
  ld a, SIGNED_BASELINE
  ld [jumpVelocity], a
  ; Adjust the player to rest exactly on top of the ground tile
  ld a, [verticalPosition]
  sub a, 1
  and 7 ; modulo 8
  ld b, a
  ld a, [verticalPosition]
  sub a, b
  ld [verticalPosition], a
  ret

; d = Y value
; e = X value
; out hl = memory address of the player's
ResolveTileAddress:
  ; What vertical row is the player on?
  ld a, d
  ld b, 8
  call DivideAB
  ld hl, MapData
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
  ld a, e
  ld b, 8
  call DivideAB
  ; the divide result is in c, set b to 0 so bc = c
  ld b, 0
  add hl, bc
  ret

CheckOnGround:
  ld a, [verticalPosition]
  sub a, 1
  ld d, a
  ld a, [rSCX]
  add a, FIXED_X_POSITION
  ld e, a
  call ResolveTileAddress
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
  ld a, [movementFlags]
  and GRIND_FLAG
  ret nz
  ; only do every 4 frames once in air
  ld a, [airTimer]
  and 3 ; modulo 4
  ret nz
  ld a, [jumpVelocity]
  dec a
  cp SIGNED_BASELINE - 3
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
