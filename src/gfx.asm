INCLUDE "hardware.inc"
INCLUDE "defines.inc"

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
  ld de, GfxData
  ld bc, EndGfxData - GfxData
  call CopyMemory
  ; Copy tilemap data
  ld hl, _SCRN0
  ld de, MapData
  ld bc, EndMapData - MapData
  call CopyMemory
  ; Set up sprite to display on screen
  call SetupPlayerSprite
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

PositionPlayerSprite::
  ; set X values first
  ld a, 40
  ld [_OAMRAM+1], a     ; top-left
  ld [_OAMRAM+5], a     ; botom-left
  add a, 8
  ld [_OAMRAM+9], a     ; top-right
  ld [_OAMRAM+13], a    ; bottom-right

  ; set Y values
  ld a, [verticalPosition]
  ld [_OAMRAM], a       ; top-left
  ld [_OAMRAM+8], a     ; top-right
  add a, 8
  ld [_OAMRAM+4], a     ; bottom-left
  ld [_OAMRAM+12], a    ; bottom-right
  ret

SetupPlayerSprite:
  call PositionPlayerSprite
  ; top-left
  ld a, 21
  ld [_OAMRAM+2], a
  ; bottom-left
  ld a, 22
  ld [_OAMRAM+6], a
  ; top-right
  ld a, 23
  ld [_OAMRAM+10], a
  ; bottom-right
  ld a, 24
  ld [_OAMRAM+14], a
  ret

AnimateHead::
  ld a, [headAnimationTimer]
  dec a
  jr nz, .timerIsNotZero
    ld a, [_OAMRAM+2]
    cp 21
    jr nz, .secondSpriteInUse
      ld a, 25
      ld [_OAMRAM+2], a
      ld a, 27
      ld [_OAMRAM+10], a
      jr .endSpriteSwap
    .secondSpriteInUse
      ld a, 21
      ld [_OAMRAM+2], a
      ld a, 23
      ld [_OAMRAM+10], a
    .endSpriteSwap
    ld a, 100
  .timerIsNotZero
  ld [headAnimationTimer], a
  ret

AnimateLegs::
  ld a, [legsAnimationTimer]
  dec a
  jr nz, .timerIsNotZero
    ld a, [_OAMRAM+6]
    cp 22
    jr nz, .secondSpriteInUse
      ld a, 26
      ld [_OAMRAM+6], a
      ld a, 28
      ld [_OAMRAM+14], a
      jr .endSpriteSwap
    .secondSpriteInUse
      ld a, 22
      ld [_OAMRAM+6], a
      ld a, 24
      ld [_OAMRAM+14], a
    .endSpriteSwap
    ld a, 2
  .timerIsNotZero
  ld [legsAnimationTimer], a
  ret

GfxData:
INCLUDE "gfx/tiles.asm"
INCLUDE "gfx/sprites.asm"
EndGfxData:

MapData:
INCLUDE "gfx/sample-map.asm"
EndMapData: