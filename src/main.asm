INCLUDE "hardware.inc"

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
; Zero out sprite attribute data
  ld hl, _OAMRAM
  ld bc, 40*4 ; 40 sprites, 4 bytes each
  call ZeroMemory
; Copy sprite data 
  ld hl, _VRAM
  ld de, SpriteData
  ld bc, EndSpriteData - SpriteData
  call CopyMemory
; Set up sprite to display on screen (TODO cleanup)
  ; top-left
  ld a, 80
  ld [_OAMRAM], a
  ld [_OAMRAM+1], a
  ld a, 1
  ld [_OAMRAM+2], a
  ; bottom-left
  ld a, 88
  ld [_OAMRAM+4], a
  ld a, 80
  ld [_OAMRAM+5], a
  ld a, 2
  ld [_OAMRAM+6], a
  ; top-right
  ld a, 80
  ld [_OAMRAM+8], a
  ld a, 88
  ld [_OAMRAM+9], a
  ld a, 3
  ld [_OAMRAM+10], a
  ; bottom-right
  ld a, 88
  ld [_OAMRAM+12], a
  ld [_OAMRAM+13], a
  ld a, 4
  ld [_OAMRAM+14], a
; Initialise palettes
  ld a, %11100100
  ld [rOBP0], a
; Turn display back on
  ld a, LCDCF_ON|LCDCF_BGOFF|LCDCF_WINOFF|LCDCF_OBJ8|LCDCF_OBJON
  ld [rLCDC], a
GameLoop:
  ; call WaitForNextVerticalBlank
  ; ... do stuff
; Should be displaying now, nothing to do
  .sleep
    halt
  jr .sleep

INCLUDE "core.asm"

SpriteData:
DS 16 ; Pad 16 bytes so sprite 0 is always blank
INCLUDE "gfx/sprites.asm"
EndSpriteData: