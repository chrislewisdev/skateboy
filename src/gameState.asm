INCLUDE "hardware.inc"
INCLUDE "defines.inc"

TILE_SIZE         EQU 8
GROUND_TILE       EQU 17
OLLIE_FORCE_HI    EQU SIGNED_BASELINE + 4
OLLIE_FORCE_LO    EQU 200
GRAVITY_HI        EQU 0
GRAVITY_LO        EQU 70
FALL_SPEED_LIMIT  EQU SIGNED_BASELINE - 6
GRIND_TILE_START  EQU 2
GRIND_TILE_END    EQU 5
GRIND_GRACE_LIMIT EQU 30
SPRITE_SIZE       EQU 32
SCREEN_Y_BASE     EQU 16
SPRITE_Y_OFFSET   EQU 2
GRIND_CLEARANCE   EQU 3

SECTION "Local variables - gameState.asm", WRAM0
jumpVelocity:
  .hi db
  .lo db
grindGraceTimer: db

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
    call CheckJumpInput
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

CheckJumpInput:
  ld a, [previousInput]
  and BTN_A
  ret nz
    ld a, [input]
    and BTN_A
    ret z
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
