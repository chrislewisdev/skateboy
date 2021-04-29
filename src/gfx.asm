INCLUDE "hardware.inc"
INCLUDE "defines.inc"

SPEED EQU 2

SECTION "Local variables - gfx.asm", WRAM0
mapLoadIndex: db
mapInsertIndex: db
  
SECTION "Assets", ROM0
TileData:
INCBIN "data/tiles.bin"
SpriteData:
INCBIN "gen/sprites.2bpp"
EndGfxData:

PlayerAnimations:
INCBIN "gen/sprites.anim"
EndPlayerAnimations:
PlayerHeadFramesCount EQU 3

MapData::
INCBIN "data/grand-st-mall.bin"
EndMapData::

MapHeight   EQU 18
MapWidth    EQU (EndMapData - MapData) / MapHeight
EXPORT MapHeight, MapWidth

SECTION "Graphics functions", ROM0
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

; Frame indices for the skater animations
SKTR_BASE_FRAME       EQU (SpriteData - TileData) / 16

MACRO SetPlayerHeadFrame
  ld hl, PlayerAnimations
  ld bc, \1 * 8
  add hl, bc
Y = 0
REPT 2
X = 0
REPT 4
  ld a, [hl]
  add SKTR_BASE_FRAME
  ld [SPR0_ID + (X * 4) + (Y * 16)], a
  inc hl
X = X + 1
ENDR
Y = Y + 1
ENDR
ENDM

MACRO SetPlayerLegsFrame
  ld hl, PlayerAnimations + PlayerHeadFramesCount * 8
  ld bc, \1 * 8
  add hl, bc
Y = 2
REPT 2
X = 0
REPT 4
  ld a, [hl]
  add SKTR_BASE_FRAME
  ld [SPR0_ID + (X * 4) + (Y * 16)], a
  inc hl
X = X + 1
ENDR
Y = Y + 1
ENDR
ENDM

InitGraphics::
  ; Wait until vblank, disable screen so we can initialise things
  call WaitForNextVerticalBlank
  ld a, [rLCDC]
  xor LCDCF_ON
  ld [rLCDC], a
  ; Zero out tile memory
  ld hl, _VRAM
  ld bc, $800
  call ZeroMemory
  ; Zero out tilemap
  ld hl, _SCRN0
  ld bc, 32*32
  call ZeroMemory
  ; Zero out sprite attribute data
  ld hl, _OAMRAM
  ld bc, 40*4 ; 40 sprites, 4 bytes each
  call ZeroMemory
  ; Copy sprite data 
  ld hl, _VRAM
  ld de, TileData
  ld bc, EndGfxData - TileData
  call CopyMemory
  call CopyMapData
  ; Set up sprite to display on screen
  SetPlayerHeadFrame 0
  SetPlayerLegsFrame 0
  call UpdateSprites
  ; Initialise palettes
  ld a, %11100100
  ld [rOBP0], a
  ld [rOBP1], a
  ld [rBGP], a
  ; Reset scroll registers
  ld a, 0
  ld [rSCX], a
  ld [rSCY], a
  ld [mapInsertIndex], a
  ld [mapProgressIndex], a
  ld a, 32 % MapWidth
  ld [mapLoadIndex], a
  ; Turn display back on
  ld a, LCDCF_ON|LCDCF_BG8000|LCDCF_BG9800|LCDCF_BGON|LCDCF_WINOFF|LCDCF_OBJ8|LCDCF_OBJON
  ld [rLCDC], a
  ret

UpdateGraphics::
  call DetermineAnimationFrames
  call UpdateSprites
  call ScrollRight
  ret

ScrollRight:
  ; TODO: Load from a state variable
  ld a, [rSCX]
  add a, SPEED
  ld [rSCX], a
  ; Can we load a new column now?
  ld a, [loadTriggerCounter]
  sub SPEED
  jr nc, .doNotLoadNewColumn
    add a, 8
    ld [loadTriggerCounter], a
    call LoadNewMapColumn
    ret
  .doNotLoadNewColumn
    ld [loadTriggerCounter], a
    ret

UpdateSprites:
  ; set X values first
X = 0
REPT 4
  ld a, FIXED_X_POSITION + (X * 8)
Y = 0
REPT 4
  ld [SPR0_X + (X * 4) + (Y * 16)], a
Y = Y + 1
ENDR
X = X + 1
ENDR

  ; set Y values
Y = 0
REPT 4
  ld a, [verticalPosition.hi]
  add a, Y * 8
X = 0
REPT 4
  ld [SPR0_Y + (X * 4) + (Y * 16)], a
X = X + 1
ENDR
Y = Y + 1
ENDR
  ret

InitSprites:
  SetPlayerHeadFrame 0
  SetPlayerLegsFrame 0
  ret

DetermineAnimationFrames:
  ; Grind status takes first priority
  ld a, [movementFlags]
  and GRIND_FLAG
  jp nz, .grindStance
  ; Are we in the air? If not, skip trick animations
  ld a, [airTimer]
  ld d, a
  or a
  jp z, .defaultStance
  ; Now check for trick animations
  ld a, [trickId]
  cp TRICK_OLLIE
  jp z, .ollieAnimation
  cp TRICK_SHUVIT
  jp z, .shuvitAnimation
  cp TRICK_KICKFLIP
  jp z, .kickflipAnimation
.ollieAnimation
  SetPlayerHeadFrame 2
  ld a, d
  cp 10
  jp nc, .ollieFrame2
  .ollieFrame1
    SetPlayerLegsFrame 2
    ret
  .ollieFrame2
    SetPlayerLegsFrame 0
    ret
.shuvitAnimation
  SetPlayerHeadFrame 2
  ld a, d
  cp 5
  jp c, .shuvitFrame1
  cp 12
  jp c, .shuvitFrame2
  cp 19
  jp c, .shuvitFrame3
  cp 26
  jp c, .shuvitFrame4
  .shuvitFrame5
    SetPlayerLegsFrame 0
    ret
  .shuvitFrame1
    SetPlayerLegsFrame 2
    ret
  .shuvitFrame2
    SetPlayerLegsFrame 3
    ret
  .shuvitFrame3
    SetPlayerLegsFrame 4
    ret
  .shuvitFrame4
    SetPlayerLegsFrame 5
    ret
.kickflipAnimation
  SetPlayerHeadFrame 2
  ld a, d
  cp 5
  jp c, .kickflipFrame1
  cp 12
  jp c, .kickflipFrame2
  cp 19
  jp c, .kickflipFrame3
  cp 26
  jp c, .kickflipFrame4
.kickflipFrame6
  SetPlayerLegsFrame 0
  ret
.kickflipFrame1
  SetPlayerLegsFrame 2
  ret
.kickflipFrame2
  SetPlayerLegsFrame 6
  ret
.kickflipFrame3
  SetPlayerLegsFrame 7
  ret
.kickflipFrame4
  SetPlayerLegsFrame 8
  ret
.grindStance
  SetPlayerHeadFrame 2
  SetPlayerLegsFrame 2
  ret
.defaultStance
  SetPlayerHeadFrame 0
  SetPlayerLegsFrame 0
  ret

CopyMapData:
  ld de, _SCRN0
  ld hl, MapData
REPT MapHeight
  ld bc, 32
  push hl
  call CopyGfxMemory
  pop hl
  ld bc, MapWidth
  add hl, bc
ENDR
  ret

LoadNewMapColumn:
  ; Determine where to place our new column data
  ld a, [mapInsertIndex]
  ld hl, _SCRN0
  ld b, 0
  ld c, a
  add hl, bc
  ld d, h
  ld e, l
  ; Where are we up to in the level?
  ld a, [mapLoadIndex]
  ld hl, MapData
  ld b, 0
  ld c, a
  add hl, bc
  ld b, h
  ld c, l
  ; Copy the full column
REPT MapHeight
  ld a, [bc]
  ld [de], a
  ld h, b
  ld l, c
  ld b, 0
  ld c, MapWidth
  add hl, bc
  ld b, h
  ld c, l
  ld h, d
  ld l, e
  ld d, 0
  ld e, 32
  add hl, de
  ld d, h
  ld e, l
ENDR
  ; Update indices
  ld a, [mapInsertIndex]
  inc a
  and 31 ; modulo 32
  ld [mapInsertIndex], a

  ld a, [mapLoadIndex]
  inc a
  cp MapWidth
  jr nz, .doNotResetLoadIndex
    ld a, 0
  .doNotResetLoadIndex
  ld [mapLoadIndex], a

  ; TODO reconsider if we can track progress a better way
  ld a, [mapProgressIndex]
  inc a
  cp MapWidth
  jr nz, .doNotResetProgressIndex
    ld a, 0
  .doNotResetProgressIndex
  ld [mapProgressIndex], a
  ret

; implementation of CopyMemory that flips hl/de usage
; de = destination address
; hl = source address
; bc = no. bytes to copy
CopyGfxMemory:
.untilAllDataIsCopied
  ld a, [hl]
  ld [de], a
  inc hl
  inc de
  dec bc
  ld a, b
  or c
jr nz, .untilAllDataIsCopied
ret