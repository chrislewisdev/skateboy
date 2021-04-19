INCLUDE "hardware.inc"
INCLUDE "defines.inc"

SECTION "ROM Title", ROM0[$0134]
  DB "Skateboy"

SECTION "Nintendo Logo", ROM0[$0104]
  NINTENDO_LOGO

SECTION "Entrypoint", ROM0[$0100]
  nop
  jp Startup

SECTION "Game code", ROM0[$0150]
Startup:
  call InitGameState
  call InitGraphics
GameLoop:
  call WaitForNextVerticalBlank
  call UpdateGraphics
  call UpdateGameState
  ld a, [frameCounter]
  inc a
  ld [frameCounter], a
  jp GameLoop
