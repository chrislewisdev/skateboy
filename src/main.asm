INCLUDE "hardware.inc"

headAnimationTimer EQU _RAM
legsAnimationTimer EQU _RAM+1
input EQU _RAM+2

BTN_DOWN EQU %10000000
BTN_UP EQU %01000000
BTN_LEFT EQU %00100000
BTN_RIGHT EQU %00010000
BTN_START EQU %00001000
BTN_SELECT EQU %00000100
BTN_B EQU %00000010
BTN_A EQU %00000001

SECTION "ROM Title", ROM0[$0134]
  DB "Skateboy"

SECTION "Nintendo Logo", ROM0[$0104]
  NINTENDO_LOGO

SECTION "Entrypoint", ROM0[$0100]
  nop
  jp Startup

SECTION "Game code", ROM0[$0150]
Startup:
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
  ld a, 10
  ld [legsAnimationTimer], a
  ; top-left
  ld a, 80
  ld [_OAMRAM], a
  ld [_OAMRAM+1], a
  ld a, 19
  ld [_OAMRAM+2], a
  ; bottom-left
  ld a, 88
  ld [_OAMRAM+4], a
  ld a, 80
  ld [_OAMRAM+5], a
  ld a, 20
  ld [_OAMRAM+6], a
  ; top-right
  ld a, 80
  ld [_OAMRAM+8], a
  ld a, 88
  ld [_OAMRAM+9], a
  ld a, 21
  ld [_OAMRAM+10], a
  ; bottom-right
  ld a, 88
  ld [_OAMRAM+12], a
  ld [_OAMRAM+13], a
  ld a, 22
  ld [_OAMRAM+14], a
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
GameLoop:
  call WaitForNextVerticalBlank
  call ReadInput
  call AnimateHead
  call AnimateLegs
  jp GameLoop

ReadInput:
  ld a, P1F_GET_DPAD
  ld [rP1], a
  ld a, [rP1]
  ld a, [rP1]
  ld a, [rP1]
  ld a, [rP1]
  and a, %1111
  swap a
  ld b, a
  ld a, P1F_GET_BTN
  ld [rP1], a
  ld a, [rP1]
  ld a, [rP1]
  ld a, [rP1]
  ld a, [rP1]
  and a, %1111
  or a, b
  cpl
  ld [input], a
  ret

AnimateHead:
  ld a, [headAnimationTimer]
  dec a
  jr nz, .timerIsNotZero
    ld a, [_OAMRAM+2]
    cp 19
    jr nz, .secondSpriteInUse
      ld a, 23
      ld [_OAMRAM+2], a
      ld a, 25
      ld [_OAMRAM+10], a
      jr .endSpriteSwap
    .secondSpriteInUse
      ld a, 19
      ld [_OAMRAM+2], a
      ld a, 21
      ld [_OAMRAM+10], a
    .endSpriteSwap
    ld a, 100
  .timerIsNotZero
  ld [headAnimationTimer], a
  ret

AnimateLegs:
  ld a, [legsAnimationTimer]
  dec a
  jr nz, .timerIsNotZero
    ld a, [_OAMRAM+6]
    cp 20
    jr nz, .secondSpriteInUse
      ld a, 24
      ld [_OAMRAM+6], a
      ld a, 26
      ld [_OAMRAM+14], a
      jr .endSpriteSwap
    .secondSpriteInUse
      ld a, 20
      ld [_OAMRAM+6], a
      ld a, 22
      ld [_OAMRAM+14], a
    .endSpriteSwap
    ld a, 5
  .timerIsNotZero
  ld [legsAnimationTimer], a
  ret

INCLUDE "core.asm"

GfxData:
INCLUDE "gfx/tiles.asm"
INCLUDE "gfx/sprites.asm"
EndGfxData:

MapData:
INCLUDE "gfx/sample-map.asm"
EndMapData: