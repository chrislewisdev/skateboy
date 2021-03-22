INCLUDE "hardware.inc"
INCLUDE "defines.inc"

ANMT_HEAD     EQU %00000001
ANMT_LEGS     EQU %00000010

SECTION "Graphics functions", ROM0

TileData:
INCBIN "data/tiles.bin"
SpriteData:
INCBIN "data/sprites32.bin"
EndGfxData:

MapData::
INCBIN "data/sample-map.bin"
EndMapData::

MapHeight   EQU 18
MapWidth    EQU (EndMapData - MapData) / MapHeight
EXPORT MapHeight, MapWidth

; Frame indices for the skater animations
SKTR_BASE_FRAME       EQU (SpriteData - TileData) / 16
SKTR_HEAD_A_FRAME0    EQU SKTR_BASE_FRAME
SKTR_HEAD_B_FRAME0    EQU SKTR_BASE_FRAME+2
SKTR_LEG_A_FRAME0     EQU SKTR_BASE_FRAME+1
SKTR_LEG_B_FRAME0     EQU SKTR_BASE_FRAME+3
SKTR_HEAD_A_FRAME1    EQU SKTR_BASE_FRAME+4
SKTR_HEAD_B_FRAME1    EQU SKTR_BASE_FRAME+6
SKTR_LEG_A_FRAME1     EQU SKTR_BASE_FRAME+5
SKTR_LEG_B_FRAME1     EQU SKTR_BASE_FRAME+7
SKTR_HEAD_A_OLLIE     EQU SKTR_BASE_FRAME+8
SKTR_HEAD_B_OLLIE     EQU SKTR_BASE_FRAME+10
SKTR_LEG_A_OLLIE      EQU SKTR_BASE_FRAME+9
SKTR_LEG_B_OLLIE      EQU SKTR_BASE_FRAME+11

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
  ; Copy tilemap data
  ; ld hl, _SCRN0
  ; ld de, MapData
  ; ld bc, EndMapData - MapData
  call CopyMapData
  ; Set up sprite to display on screen
  call InitSprites
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

UpdateSprites::
  ; set X values first
  ; ld b, b
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
  ; ld a, FIXED_X_POSITION
  ; ld [SPR0_X], a     ; top-left
  ; ld [SPR1_X], a     ; bottom-left
  ; add a, 8
  ; ld [SPR2_X], a     ; top-right
  ; ld [SPR3_X], a    ; bottom-right

  ld a, [verticalPosition]
Y = 0
REPT 4
X = 0
REPT 4
  ld [SPR0_Y + (X * 4) + (Y * 16)], a
X = X + 1
ENDR
  add a, 8
Y = Y + 1
ENDR
  ; set Y values
  ; ld a, [verticalPosition]
  ; ld [SPR0_Y], a       ; top-left
  ; ld [SPR2_Y], a     ; top-right
  ; add a, 8
  ; ld [SPR1_Y], a     ; bottom-left
  ; ld [SPR3_Y], a    ; bottom-right
  ret

InitSprites:
; COUNTER = 0
; REPT 16
; X = (COUNTER % 4 % 2)
; Y = (COUNTER % 4 % 2) + 1
;   ld a, SKTR_BASE_FRAME + COUNTER
;   ld [SPR0_ID + (X * 4) + (Y * 16)], a
; COUNTER = COUNTER + 1
; ENDR
  ld a, SKTR_BASE_FRAME
  ld [SPR0_ID], a
  inc a
  ld [SPR0_ID + 16], a
  inc a
  ld [SPR0_ID + 4], a
  inc a
  ld [SPR0_ID + 4 + 16], a
  inc a
  ld [SPR0_ID + 32], a
  inc a
  ld [SPR0_ID + 48], a
  inc a
  ld [SPR0_ID + 32 + 4], a 
  inc a
  ld [SPR0_ID + 48 + 4], a
  inc a
  ld [SPR0_ID + 8], a
  inc a
  ld [SPR0_ID + 8 + 16], a
  inc a
  ld [SPR0_ID + 12], a
  inc a
  ld [SPR0_ID + 12 + 16], a
  inc a
  ld [SPR0_ID + 8 + 32],a
  inc a
  ld [SPR0_ID + 8 + 48], a
  inc a
  ld [SPR0_ID + 12 + 32], a
  inc a
  ld [SPR0_ID + 12 + 48], a
;   ld a, SKTR_BASE_FRAME + COUNTER
;   ld [SPR0_ID + (4 * COUNTER)], a
; COUNTER = COUNTER + 1
; ENDR
  ret

DetermineAnimationFrames::
  ; Process two-frame animation flags
  ld a, [frameCounter]
  ld b, a
  and a, 63 ; modulo 64
  jr nz, .headTimerIsNotZero
    ld a, [animationFlags]
    xor ANMT_HEAD
    ld [animationFlags], a
  .headTimerIsNotZero
  ld a, b
  and a, 1 ;modulo 2
  jr nz, .legsTimerIsNotZero
    ld a, [animationFlags]
    xor ANMT_LEGS
    ld [animationFlags], a
  .legsTimerIsNotZero
  call AnimateHead
  call AnimateLegs
  ; Check for ollie state
  ld a, [airTimer]
  ld b, a
  or a
  jr z, .isNotOllieing
    ld a, SKTR_HEAD_A_OLLIE
    ld [SPR0_ID], a
    ld a, SKTR_HEAD_B_OLLIE
    ld [SPR2_ID], a
    ld a, b
    cp 10
    jr c, .isOllieing
    ld a, [movementFlags]
    and GRIND_FLAG
    jr nz, .isOllieing
    jr .isNotOllieing
    ; TODO rename these... it is not just for ollieing
    .isOllieing
      ld a, SKTR_LEG_A_OLLIE
      ld [SPR1_ID], a
      ld a, SKTR_LEG_B_OLLIE
      ld [SPR3_ID], a
      ret
  .isNotOllieing
  ret

AnimateHead:
  ld a, [animationFlags]
  and ANMT_HEAD
  jr nz, .secondSpriteInUse
    ld a, SKTR_HEAD_A_FRAME1
    ld [SPR0_ID], a
    ld a, SKTR_HEAD_B_FRAME1
    ld [SPR2_ID], a
    jr .endSpriteSwap
  .secondSpriteInUse
    ld a, SKTR_HEAD_A_FRAME0
    ld [SPR0_ID], a
    ld a, SKTR_HEAD_B_FRAME0
    ld [SPR2_ID], a
  .endSpriteSwap
  ret

AnimateLegs:
  ld a, [animationFlags]
  and ANMT_LEGS
  jr nz, .secondSpriteInUse
    ld a, SKTR_LEG_A_FRAME1
    ld [SPR1_ID], a
    ld a, SKTR_LEG_B_FRAME1
    ld [SPR3_ID], a
    jr .endSpriteSwap
  .secondSpriteInUse
    ld a, SKTR_LEG_A_FRAME0
    ld [SPR1_ID], a
    ld a, SKTR_LEG_B_FRAME0
    ld [SPR3_ID], a
  .endSpriteSwap
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

LoadNewMapColumn::
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
CopyGfxMemory::
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