.INCLUDE "std.inc"
.INCLUDE "os.inc"

.macro print_inline string
.local @string
.local @end
    lda #<@string
    ldx #>@string
    jsr os_print_string
    jmp @end
@string:
    .byte string, $0A, $0D, $00
@end:
.endmacro

.ZEROPAGE
last_stat: .res $1
loop_count: .res $1
; lba_low: .res $1
; lba_mid: .res $1
; lba_high: .res $1
next_pattern: .res $1
auto_inc: .res $1
cur_pos: .res $1

.BSS
input_buf: .res $100
input_buf_h: .res $100

.CODE
    jsr os_get_event
    cmp #OS_EVENT_INIT 
    bne :+
    jmp event_init
:
    cmp #OS_EVENT_KEY
    bne :+
    jmp event_key
:
    cmp #OS_EVENT_TIMER
    bne :+
    jmp event_timer
:
    rts

event_init:
    ; set up to write to ide disk starting at lba 1
    lda #$00
    sta cur_pos
    lda #$1
    ; lda #$71
    ldx #$00
    ldy #$00
    jsr os_ide_set_lba

    ; expecting arguments: dd <filename>
    jsr os_get_argn
    cmp #$02
    bne @missing_arg
    ; get first argument (filename)
    lda #$01
    jsr os_get_arg

    ; open file for reading
    jsr os_fopen
    bcc @file_not_found

    ; loop over blocks until eof, writing each to ide
@block_loop:
    ; compare if cur_pos is >= $10 and cur_pos < $20 and only call os_id_write_block if true
    lda cur_pos
    sta ARG0
    cmp #$10
    ; cmp #$e0
    bcc @no_write
    lda cur_pos
    cmp #$20
    ; cmp #$fe
    bcs @no_write

    print_inline "writing block"
    jsr os_dbg_byte
    ; after os_fopen the first block is already in the io buffer.
    ; write it to ide. lba is auto incremented by os_ide_write_block.
    jsr os_ide_write_block
@no_write:
    ; advance to next block
    jsr os_fnext_block
    inc cur_pos
    inc cur_pos
    bcs @block_loop
    rts

@missing_arg:
    print_inline "Error: missing filename argument"
    rts

@file_not_found:
    print_inline "Error: file not found"
    rts

event_key:
    rts

event_timer:
    rts



