INCLUDE "hardware.inc"
INCLUDE "defines.inc"

SECTION "ROM Title", ROM0[$0134]
  DB "Skateboy"

SECTION "Nintendo Logo", ROM0[$0104]
  NINTENDO_LOGO

SECTION "Entrypoint", ROM0[$0100]
  nop
  jp Startup

SECTION "Vertical blank handler", ROM0[$0040]
  call VerticalBlankHandler
  reti

SECTION "Game code", ROM0[$0150]
Startup:
  di
  call InitGameState
  call InitGraphics
  ; Enable vblank interrupt only
  ld a, IEF_VBLANK
  ld [rIE], a
  ei
GameLoop:
  call WaitForNextVerticalBlankViaInterrupt
  call UpdateGraphics
  call UpdateGameState
  ld a, [frameCounter]
  inc a
  ld [frameCounter], a
  ; Uncomment to run at lower speeds
;   and 7
;   jp z, GameLoop
; REPT 7
;   call WaitForNextVerticalBlankViaInterrupt
; ENDR
  jp GameLoop
