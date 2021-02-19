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
; Copy sprite data
  ld hl, _VRAM
  ld de, SpriteData
  ld bc, EndSpriteData - SpriteData
  call CopyMemory
; TODO - Set up sprite to display on screen
; TODO - Initialise palettes
; Turn display back on
  ld a, [rLCDC]
  or LCDCF_ON
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