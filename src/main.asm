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
    call CheckJumpInput
    call CheckLanding
    jr .endOfGroundCheck
  .notOnGround
    call DecayVelocity
  .endOfGroundCheck
  call EvaluateVelocity
  call PositionPlayerSprite
  jp GameLoop

InitState:
  ld a, SIGNED_BASELINE
  ld [jumpVelocity], a
  ld a, 2
  ld [legsAnimationTimer], a
  ld a, 100
  ld [headAnimationTimer], a
  ld a, 113
  ld [verticalPosition], a

ScrollRight:
  ld a, [rSCX]
  add a, 1
  ld [rSCX], a
  ret

CheckJumpInput:
  ld a, [previousInput]
  and BTN_A
  ret nz
    ld a, [input]
    and BTN_A
    ret z
      ld a, SIGNED_BASELINE + 5
      ld [jumpVelocity], a
  ret

CheckLanding:
  ld a, [jumpVelocity]
  cp SIGNED_BASELINE
  ret nc
  ld a, SIGNED_BASELINE
  ld [jumpVelocity], a
  ret

CheckOnGround:
  ; What vertical row is the player on?
  ld a, [verticalPosition]
  ld b, 8
  call DivideAB
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
  add a, 40 ; constant X position
  ld b, 8
  call DivideAB
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
  ; decay velocity
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
  ; jr z, .endOfJumpLogic
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
