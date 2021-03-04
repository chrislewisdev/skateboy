INCLUDE "hardware.inc"
INCLUDE "defines.inc"

SECTION "Core functions", ROM0
; Waits for the START of a new vblank period to ensure maximum time is available.
WaitForNextVerticalBlank::
  .untilVerticalBlank
    ld a, [rLY]
    cp 144
  jr nz, .untilVerticalBlank
  ret

; hl = destination address
; bc = no. bytes to zero
ZeroMemory::
  .untilAllBytesAreZeroed
    ld [hl], $00
    inc hl
    dec bc
    ld a, b
    or c
  jr nz, .untilAllBytesAreZeroed
  ret

; hl = destination address
; de = source address
; bc = no. bytes to copy
CopyMemory::
  .untilAllDataIsCopied
    ld a, [de]
    ld [hli], a
    inc de
    dec bc
    ld a, b
    or c
  jr nz, .untilAllDataIsCopied
  ret

; a = top of fraction
; b = bottom of fraction
; out c = (a / b)
DivideAB::
  ld c, 0
  .untilDivisionComplete
    sub a, b
    ret c
    inc c
  jr .untilDivisionComplete

ReadInput::
  ld a, [input]
  ld [previousInput], a
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
