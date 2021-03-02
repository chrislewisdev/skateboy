INCLUDE "hardware.inc"
INCLUDE "defines.inc"

; Frame indices for the skater animations
SKTR_HEAD_A_FRAME0    EQU 21
SKTR_HEAD_B_FRAME0    EQU 23
SKTR_LEG_A_FRAME0     EQU 22
SKTR_LEG_B_FRAME0     EQU 24
SKTR_HEAD_A_FRAME1    EQU 25
SKTR_HEAD_B_FRAME1    EQU 27
SKTR_LEG_A_FRAME1     EQU 26
SKTR_LEG_B_FRAME1     EQU 28

SECTION "Graphics functions", ROM0
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
  ld hl, _SCRN0
  ld de, MapData
  ld bc, EndMapData - MapData
  call CopyMemory
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
  ; Turn display back on
  ld a, LCDCF_ON|LCDCF_BG8000|LCDCF_BG9800|LCDCF_BGON|LCDCF_WINOFF|LCDCF_OBJ8|LCDCF_OBJON
  ld [rLCDC], a
  ret

UpdateSprites::
  ; set X values first
  ld a, FIXED_X_POSITION
  ld [SPR0_X], a     ; top-left
  ld [SPR1_X], a     ; bottom-left
  add a, 8
  ld [SPR2_X], a     ; top-right
  ld [SPR3_X], a    ; bottom-right

  ; set Y values
  ld a, [verticalPosition]
  ld [SPR0_Y], a       ; top-left
  ld [SPR2_Y], a     ; top-right
  add a, 8
  ld [SPR1_Y], a     ; bottom-left
  ld [SPR3_Y], a    ; bottom-right
  ret

InitSprites:
  ; top-left
  ld a, SKTR_HEAD_A_FRAME0
  ld [SPR0_ID], a
  ; bottom-left
  ld a, SKTR_LEG_A_FRAME0
  ld [SPR1_ID], a
  ; top-right
  ld a, SKTR_HEAD_B_FRAME0
  ld [SPR2_ID], a
  ; bottom-right
  ld a, SKTR_LEG_B_FRAME0
  ld [SPR3_ID], a
  ret

AnimateHead::
  ld a, [frameCounter]
  and a, 63 ; modulo 64
  jr nz, .timerIsNotZero
    ld a, [SPR0_ID]
    cp SKTR_HEAD_A_FRAME0
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
  .timerIsNotZero
  ret

AnimateLegs::
  ld a, [frameCounter]
  and a, 1  ; modulo 2
  jr nz, .timerIsNotZero
    ld a, [SPR1_ID]
    cp SKTR_LEG_A_FRAME0
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
  .timerIsNotZero
  ret

TileData:
INCBIN "data/tiles.bin"
SpriteData:
INCBIN "data/sprites.bin"
EndGfxData:

MapData:
INCBIN "data/sample-map.bin"
EndMapData: