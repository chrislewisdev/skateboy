INCLUDE "hardware.inc"
INCLUDE "defines.inc"

SECTION "Game state logic", ROM0

TILE_SIZE         EQU 8
GROUND_TILE       EQU 17
OLLIE_FORCE       EQU SIGNED_BASELINE + 3
FALL_SPEED_LIMIT  EQU SIGNED_BASELINE - 3
GRIND_TILE_START  EQU 2
GRIND_TILE_END    EQU 5
GRIND_GRACE_LIMIT EQU 30
SPRITE_SIZE       EQU 32
SCREEN_Y_BASE     EQU 16
SPRITE_Y_OFFSET   EQU 2
GRIND_CLEARANCE   EQU 3

InitGameState::
  ld a, SIGNED_BASELINE
  ld [jumpVelocity], a
  ld a, 30
  ld [verticalPosition], a
  ld a, 0
  ld [movementFlags], a
  ld [grindGraceTimer], a
  ld a, 16
  ld [loadTriggerCounter], a

UpdateGameState::
  call ReadInput
  call CheckOnGround
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
  ld a, [movementFlags]
  and GROUND_FLAG
  jr z, .notOnGround
  .onGround
    call PerformGroundChecks
    jr .endOfGroundCheck
  .notOnGround
    call PerformAirChecks
  .endOfGroundCheck
  call ApplyVelocity
  ret

PerformGroundChecks:
  ld a, 0
  ld [airTimer], a
  call CheckJumpInput
  call CheckLanding
  ret

PerformAirChecks:
  ld a, [airTimer]
  inc a
  ld [airTimer], a
  call CheckGrindInput
  call DecayVelocity
  ret

CheckJumpInput:
  ld a, [previousInput]
  and BTN_A
  ret nz
    ld a, [input]
    and BTN_A
    ret z
      ld a, OLLIE_FORCE
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
    cp GRIND_GRACE_LIMIT
    ret nc
    inc a
    ld [grindGraceTimer], a
    ; are we on a grindable surface?
    ld a, [verticalPosition]
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
    ld a, [verticalPosition]
    sub a, b
    add a, GRIND_CLEARANCE + SPRITE_Y_OFFSET
    ld [verticalPosition], a
    ; Set the grind flag and halt vertical movement
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
  ld a, OLLIE_FORCE
  ld [jumpVelocity], a
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
  ld a, [jumpVelocity]
  cp SIGNED_BASELINE
  ret nc
  ld a, SIGNED_BASELINE
  ld [jumpVelocity], a
  ; Adjust the player to rest exactly on top of the ground tile
  ld a, [verticalPosition]
  add a, SPRITE_SIZE - SCREEN_Y_BASE - SPRITE_Y_OFFSET
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
  ld b, TILE_SIZE
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
  ld b, TILE_SIZE
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
  ld a, [verticalPosition]
  add a, SPRITE_SIZE - SCREEN_Y_BASE - SPRITE_Y_OFFSET
  ld d, a
  ld a, [rSCX]
  and 7 ; modulo 8
  add a, FIXED_X_POSITION
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
  ; only do every 4 frames once in air
  ld a, [airTimer]
  and 3 ; modulo 4
  ret nz
  ld a, [jumpVelocity]
  dec a
  cp FALL_SPEED_LIMIT
  ret c
  ld [jumpVelocity], a
  ret

ApplyVelocity:
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
