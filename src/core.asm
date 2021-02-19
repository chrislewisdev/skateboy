; Waits for the START of a new vblank period to ensure maximum time is available.
WaitForNextVerticalBlank:
  .untilVerticalBlank
    ld a, [rLY]
    cp 144
  jr nz, .untilVerticalBlank
  ret

; hl = destination address
; bc = no. bytes to zero
ZeroMemory:
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
CopyMemory:
  .untilAllDataIsCopied
    ld a, [de]
    ld [hli], a
    inc de
    dec bc
    ld a, b
    or c
  jr nz, .untilAllDataIsCopied
  ret