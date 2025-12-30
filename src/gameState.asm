INCLUDE "hardware.inc"
INCLUDE "defines.inc"

DEF TILE_SZ           EQU 8
DEF GROUND_TILE       EQU 17
DEF OLLIE_FORCE_HI    EQU SIGNED_BASELINE + 4
DEF OLLIE_FORCE_LO    EQU 100
DEF GRAVITY_HI        EQU 0
DEF GRAVITY_LO        EQU 65
DEF FALL_SPEED_LIMIT  EQU SIGNED_BASELINE - 6
DEF GRIND_TILE_START  EQU 2
DEF GRIND_TILE_END    EQU 5
DEF GRIND_GRACE_LIMIT EQU 30
DEF SPRITE_SIZE       EQU 32
DEF SCREEN_Y_BASE     EQU 16
DEF SPRITE_Y_OFFSET   EQU 2
DEF GRIND_CLEARANCE   EQU 3

DEF TRICK_INPUT_LEFT  EQU %00
DEF TRICK_INPUT_RIGHT EQU %01
DEF TRICK_INPUT_UP    EQU %10
DEF TRICK_INPUT_DOWN  EQU %11

DEF TRICK_COMBO_SHUVIT    EQU TRICK_INPUT_RIGHT
DEF TRICK_COMBO_KICKFLIP  EQU TRICK_INPUT_DOWN

SECTION "Local variables - gameState.asm", WRAM0
jumpVelocity:
  .hi db
  .lo db
grindGraceTimer: db
trickInput: db
trickInputIndex: db

SECTION "Game state logic", ROM0
InitGameState::
  ld a, SIGNED_BASELINE
  ld [jumpVelocity.hi], a
  ld a, 30
  ld [verticalPosition.hi], a
  ld a, 0
  ld [jumpVelocity.lo], a
  ld [verticalPosition.lo], a
  ld [movementFlags], a
  ld [grindGraceTimer], a
  ld [trickInputIndex], a
  ld [trickInput], a
  ld a, 16
  ld [loadTriggerCounter], a

UpdateGameState::
  call ReadInput
  call UpdateGrindGraceTimer
  call UpdatePlayer
  ret

UpdateGrindGraceTimer:
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
  ret

UpdatePlayer:
  call ApplyVelocity
  call CheckOnGround
  ld a, [movementFlags]
  and GROUND_FLAG
  jr z, .notOnGround
  .onGround
    ld a, 0
    ld [airTimer], a
    ld a, [movementFlags]
    and TRICK_SETUP_FLAG
    jr z, .isNotSettingUpTrick
    .isSettingUpTrick
      call GatherTrickInput
      call CheckTrickRelease
      jr .endTrickSetupCheck
    .isNotSettingUpTrick
      call CheckTrickInitiation
    .endTrickSetupCheck
    call CheckLanding
    ; Still need to decay velocity if jumping
    ld a, [jumpVelocity.hi]
    cp SIGNED_BASELINE
    call nc, DecayVelocity
    jr .endOfGroundCheck
  .notOnGround
    ld a, [airTimer]
    inc a
    ld [airTimer], a
    call CheckGrindInput
    call DecayVelocity
  .endOfGroundCheck
  ret

CheckTrickInitiation:
  ld a, [previousInput]
  and BTN_A
  ret nz
    ld a, [input]
    and BTN_A
    ret z
      ld a, [movementFlags]
      or TRICK_SETUP_FLAG
      ld [movementFlags], a
  ret

; b in = the key to check for
; c in = the input id to record if pressed
CheckTrickInput:
  ; Early-exit: key is already pressed
  ld a, [previousInput]
  and b
  ret nz
  ; Early-exit: key not pressed now
  ld a, [input]
  and b
  ret z
  ; c << (trickInputIndex * 2)
  ld a, [trickInputIndex]
  and a
  jr z, .endRotationLoop
  .loopToRotateTrickByte
    rlc c
    rlc c
    dec a
    jr nz, .loopToRotateTrickByte
  .endRotationLoop
  ; trickInput &= c
  ld a, [trickInput]
  or c
  ld [trickInput], a
  ; trickInputIndex++
  ld a, [trickInputIndex]
  inc a
  ld [trickInputIndex], a
  ret

GatherTrickInput:
  ld b, BTN_LEFT
  ld c, TRICK_INPUT_LEFT
  call CheckTrickInput
  ld b, BTN_RIGHT
  ld c, TRICK_INPUT_RIGHT
  call CheckTrickInput
  ld b, BTN_UP
  ld c, TRICK_INPUT_UP
  call CheckTrickInput
  ld b, BTN_DOWN
  ld c, TRICK_INPUT_DOWN
  call CheckTrickInput
  ret

CheckTrickRelease:
  ld a, [previousInput]
  and BTN_A
  ret z

  ld a, [input]
  and BTN_A
  ret nz

  call PopBoard
  call DetermineTrickId
  call ResetTrickState
  ret

DetermineTrickId:
  ld a, [trickInputIndex]
  and a
  jr nz, .hasTrickInput
  .noTrickInput
    ld a, TRICK_OLLIE
    ld [trickId], a
    ret
  .hasTrickInput
  ld a, [trickInput]
  cp TRICK_COMBO_KICKFLIP
  jr nz, .isNotDoingKickflip
    ld a, TRICK_KICKFLIP
    ld [trickId], a
    ret
  .isNotDoingKickflip
  cp TRICK_COMBO_SHUVIT
  jr nz, .isNotDoingShuvit
    ld a, TRICK_SHUVIT
    ld [trickId], a
    ret
  .isNotDoingShuvit
  ret

ResetTrickState:
  ld a, [movementFlags]
  and ~TRICK_SETUP_FLAG
  ld [movementFlags], a
  ld a, 0
  ld [trickInput], a
  ld [trickInputIndex], a
  ret

PopBoard:
  ld a, OLLIE_FORCE_HI
  ld [jumpVelocity.hi], a
  ld a, OLLIE_FORCE_LO
  ld [jumpVelocity.lo], a
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
    cp GRIND_GRACE_LIMIT
    ret nc
    inc a
    ld [grindGraceTimer], a
    ; are we on a grindable surface?
    ld a, [verticalPosition.hi]
    add a, SPRITE_SIZE - SCREEN_Y_BASE + GRIND_CLEARANCE
    ld d, a
    ld a, [rSCX]
    and 7 ; modulo 8
    add a, FIXED_X_POSITION + 4
    ld e, a
    call ResolveTileAddress
    ld a, [hl]
    cp GRIND_TILE_START
    ret c
    cp GRIND_TILE_END
    ret nc
    ; We are on a grindable surface and B has been pressed.
    ; First align the player to the tile so they appear flush on the rail
    ld a, d
    and a, 7  ; modulo 8
    ld b, a
    ld a, [verticalPosition.hi]
    sub a, b
    add a, GRIND_CLEARANCE + SPRITE_Y_OFFSET
    ld [verticalPosition.hi], a
    ld a, 0
    ld [verticalPosition.lo], a
    ; Set the grind flag and halt vertical movement
    ld a, [movementFlags]
    or GRIND_FLAG
    ld [movementFlags], a
    ld a, SIGNED_BASELINE
    ld [jumpVelocity.hi], a
    ld a, 0
    ld [jumpVelocity.lo], a
    ret
  .continueGrind
    ld a, [input]
    and BTN_B
    jr z, .exitGrindWithOllie
      ld a, [verticalPosition.hi]
      add a, SPRITE_SIZE - SCREEN_Y_BASE + GRIND_CLEARANCE
      ld d, a
      ld a, [rSCX]
      and 7 ; modulo 8
      add a, FIXED_X_POSITION
      ld e, a
      call ResolveTileAddress
      ld a, [hl]
      cp GRIND_TILE_START
      jr c, .exitGrind
      cp GRIND_TILE_END
      jr nc, .exitGrind
      ret
  .exitGrindWithOllie
  ld a, OLLIE_FORCE_HI
  ld [jumpVelocity.hi], a
  ld a, OLLIE_FORCE_LO
  ld [jumpVelocity.lo], a
  ld a, 1
  ld [airTimer], a
  .exitGrind
  ld a, [movementFlags]
  and ~GRIND_FLAG
  ld [movementFlags], a
  ret

; To be called when the player is touching the ground
; Zeroes their vertical velocity only if falling
CheckLanding:
  ld a, [jumpVelocity.hi]
  cp SIGNED_BASELINE
  ret nc
  ld a, SIGNED_BASELINE
  ld [jumpVelocity.hi], a
  ld a, 0
  ld [jumpVelocity.lo], a
  ; Adjust the player to rest exactly on top of the ground tile
  ld a, [verticalPosition.hi]
  add a, SPRITE_SIZE - SCREEN_Y_BASE - SPRITE_Y_OFFSET
  and 7 ; modulo 8
  ld b, a
  ld a, [verticalPosition.hi]
  sub a, b
  ld [verticalPosition.hi], a
  ld a, 0
  ld [verticalPosition.lo], a
  ret

; d = Y value
; e = X value
; out hl = memory address of the player's
ResolveTileAddress:
  ; What vertical row is the player on?
  ld a, d
  ld b, TILE_SZ
  call DivideAB
  ld hl, MapData
  ld a, c
  ; TODO account for variable map widths somehow
  ld bc, MapWidth
  or a
  jr z, .rowSeekComplete
  .untilRowSeekComplete
    add hl, bc  ; one row
    dec a
    jr nz, .untilRowSeekComplete
  .rowSeekComplete
  ; What horizontal column is the player on?
  ; TODO clean up the relationship between progress index and 
  ; this math here..........
  ld a, e
  ld b, TILE_SZ
  call DivideAB
  ; the divide result is in c, set b to 0 so bc = c
  ld a, [mapProgressIndex]
  add a, c
  cp MapWidth
  jr c, .inHorizontalBounds
    sub MapWidth
  .inHorizontalBounds
  ld c, a
  ld b, 0
  add hl, bc
  ret

CheckOnGround:
  ld a, [verticalPosition.hi]
  add a, SPRITE_SIZE - SCREEN_Y_BASE - SPRITE_Y_OFFSET
  ld d, a
  ld a, [rSCX]
  and 7 ; modulo 8
  ; Check first wheel
  add a, FIXED_X_POSITION + 8
  ld e, a
  call ResolveTileAddress
  ld a, [hl]
  cp GROUND_TILE
  jr z, .onGround
  ; Check second wheel
  ld a, e
  add 24
  ld e, a
  call ResolveTileAddress
  ld a, [hl]
  cp GROUND_TILE
  jr nz, .notOnGround
  .onGround
    ld a, [movementFlags]
    or GROUND_FLAG
    ld [movementFlags], a
    ret
  .notOnGround
    ld a, [movementFlags]
    and ~GROUND_FLAG
    ld [movementFlags], a
    ret

DecayVelocity:
  ld a, [movementFlags]
  and GRIND_FLAG
  ret nz
  ld a, [jumpVelocity.lo]
  sub GRAVITY_LO
  ld b, a
  ld a, [jumpVelocity.hi]
  sbc GRAVITY_HI
  cp FALL_SPEED_LIMIT
  ret c
  ld [jumpVelocity.hi], a
  ld a, b
  ld [jumpVelocity.lo], a
  ret

ApplyVelocity:
  ld a, [jumpVelocity.hi]
  cp SIGNED_BASELINE
  ret z
  jr c, .isFalling
  .isJumping
    sub a, SIGNED_BASELINE
    ld b, a ; b = jumpVelocity.hi - signed_base
    ld a, [jumpVelocity.lo]
    ld c, a ; = c = jumpVelocity.lo
    ld a, [verticalPosition.hi]
    ld d, a ; d = verticalPosition.hi
    ld a, [verticalPosition.lo]
    ld e, a ; e = verticalPosition.lo

    ld a, e
    sub a, c
    ld [verticalPosition.lo], a
    ld a, d
    sbc a, b
    ld [verticalPosition.hi], a
    jr .endOfJumpLogic
  .isFalling
    ld b, a ; b = jumpVelocity.hi
    ld a, SIGNED_BASELINE
    sub a, b
    ld b, a ; b = signed_base - jumpVelocity.hi
    ld a, [jumpVelocity.lo]
    ld c, a ; c = jumpVelocity.lo
    ld a, [verticalPosition.hi]
    ld d, a ; d = verticalPosition.hi
    ld a, [verticalPosition.lo]
    ld e, a ; e = verticalPosition.lo

    ld a, e
    add c
    ld [verticalPosition.lo], a
    ld a, d
    adc a, b
    ld [verticalPosition.hi], a
  .endOfJumpLogic
  ret
