; UNIVERSAL FB v5 - complete single-file ACME source
; C64 / C16 / VIC-20 (unexpanded, +3K, +8K or more)
; Build: acme -f cbm -o FB universal-fb.asm
;
; Output must match reference/FB (271 bytes) byte for byte.
; The BASIC line is intentionally handwritten in BASIC 2.0 tokens.
; This is loaded with LOAD"FB",8 (NOT ,8,1), then RUN.
;
; BASIC line: 10 SYS PEEK(43)+256*PEEK(44)+27
;
; A relocatable 28-byte bootstrap copies the embedded 214-byte main
; loader to $1C00. The main loader copies its small I/O trampoline to
; $0350, then LOADs the selected browser and jumps to its startup address.

* = $0801-2
	!word $0801
* = $0801
basic_start:
    !word basic_end
    !word 10
    !byte $9e, $20                 ; SYS and space
    !byte $c2, $28                 ; PEEK(
    !text "43"
    !byte $29, $aa                 ; )+
    !text "256"
    !byte $ac, $c2, $28            ; *PEEK(
    !text "44"
    !byte $29, $aa                 ; )+
    !text "27"                    ; bootstrap offset from BASIC start
    !byte 0                       ; end of line
basic_end:
    !word 0                       ; end-of-BASIC marker

; Position independent (all absolute addresses below are intentional:
; zero page, a fixed relocation destination, or KERNAL ROM).
bootstrap:
    clc
    lda $2b
    adc #<(payload-basic_start)
    sta $fb
    lda $2c
    adc #>(payload-basic_start)
    sta $fc
    ldy #0
copy_core:
    lda ($fb),y
    sta $1c00,y
    iny
    cpy #214
    bne copy_core
    jmp $1c00

; The file byte position below is the payload to copy, but the 6502
; addresses embedded INSIDE it are assembled for $1C00. ACME pseudopc
; lets us assemble for that runtime location while emitting the bytes
; immediately after the bootstrap, with no separate binary file.
payload:
!pseudopc $1c00 {
start:
    ldx #trampoline_end-trampoline
copy_loop:
    lda trampoline_image-1,x
    sta trampoline-1,x
    dex
    bne copy_loop

    ; All three BASIC ROMs use $002B/$002C for start of BASIC.
    lda $2c
    cmp #$08           ; C64: BASIC at $0801
    beq c64
    cmp #$04           ; VIC-20 +3K: BASIC at $0401
    beq vic3
    cmp #$12           ; VIC-20 +8K: BASIC at $1201
    beq vic8
    ; Both C16 and unexpanded VIC start BASIC at $1001.
    ; KERNAL SCREEN reports 22 columns for VIC, 40 for C16.
    jsr $ffed
    cpx #22
    beq vic0
    jmp c16

c64:
    lda #fb64_end-fb64
    ldx #<fb64
    ldy #>fb64
    jsr set_name
    lda #<$080d
    ldx #>$080d
    jmp set_entry
c16:
    lda #fb16_end-fb16
    ldx #<fb16
    ldy #>fb16
    jsr set_name
    lda #<$100d
    ldx #>$100d
    jmp set_entry
vic0:
    lda #fb20_end-fb20
    ldx #<fb20
    ldy #>fb20
    jsr set_name
    lda #<$100d
    ldx #>$100d
    jmp set_entry
vic3:
    lda #fb3_end-fb3
    ldx #<fb3
    ldy #>fb3
    jsr set_name
    lda #<$040d
    ldx #>$040d
    jmp set_entry
vic8:
    lda #fb8_end-fb8
    ldx #<fb8
    ldy #>fb8
    jsr set_name
    lda #<$120d
    ldx #>$120d
    jmp set_entry

set_name:
    sta tr_name_len
    stx tr_name_lo
    sty tr_name_hi
    rts
set_entry:
    sta tr_entry_lo
    stx tr_entry_hi
    jmp trampoline

fb64: !text "FB64"
fb64_end:
fb16: !text "FB16"
fb16_end:
fb20: !text "FB20"
fb20_end:
fb3:  !text "FB20-3K"
fb3_end:
fb8:  !text "FB20-8K"
fb8_end:

; Note: !pseudopc emits this data at the current file position, but labels
; inside it are resolved for the buffer's runtime address ($0350).
trampoline_image:
!pseudopc $0350 {
trampoline:
    lda #147
    jsr $ffd2        ; CHROUT clear screen before browser load
    lda #0
    jsr $ff90        ; SETMSG suppress KERNAL SEARCHING/LOADING
    lda #1
    ldx #8
    ldy #1
    jsr $ffba        ; SETLFS (logical file 1, drive 8, SA=1)
    lda tr_name_len
    ldx tr_name_lo
    ldy tr_name_hi
    jsr $ffbd        ; SETNAM
    lda #0
    ldx #0
    ldy #0
    jsr $ffd5        ; LOAD, using PRG's own load address
    bcs load_error
    !byte $4c        ; JMP absolute, patched target
tr_entry_lo: !byte 0
tr_entry_hi: !byte 0
load_error:
    lda #63           ; '?' -- error status is in A from LOAD
    jsr $ffd2
    rts
tr_name_len: !byte 0
tr_name_lo:  !byte 0
tr_name_hi:  !byte 0
trampoline_end:
}

} ; end main loader pseudopc
