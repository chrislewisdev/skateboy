INCLUDE "hardware.inc"
INCLUDE "defines.inc"

SECTION "ROM Title", ROM0[$0134]
  DB "Skateboy"

SECTION "Nintendo Logo", ROM0[$0104]
  DB  $CE,$ED,$66,$66,$CC,$0D,$00,$0B,$03,$73,$00,$83,$00,$0C,$00,$0D
  DB  $00,$08,$11,$1F,$88,$89,$00,$0E,$DC,$CC,$6E,$E6,$DD,$DD,$D9,$99
  DB  $BB,$BB,$67,$63,$6E,$0E,$EC,$CC,$DD,$DC,$99,$9F,$BB,$B9,$33,$3E

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
  ld a, IE_VBLANK
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
