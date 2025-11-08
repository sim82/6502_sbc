.INCLUDE "std.inc"
.INCLUDE "os.inc"

.ZEROPAGE
last_stat: .res $1
loop_count: .res $1
; lba_low: .res $1
; lba_mid: .res $1
; lba_high: .res $1
next_pattern: .res $1
auto_inc: .res $1

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
    lda #$01
    ldx #$00
    ldy #$00
    jsr os_vfs_ide_set_lba

    ; expecting filename as first argument
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
    ; after os_fopen the first block is already in the io buffer.
    ; write it to ide. lba is auto incremented by os_ide_write_block.
    jsr os_ide_write_block
    ; advance to next block
    jsr os_fnext_block
    bcs @block_loop
    rts

@missing_arg_error:
    .byte "Error: missing filename argument", $0A, $0D, $00
@missing_arg:
    lda #<@missing_arg_error
    ldx #>@missing_arg_error
    jsr os_print_string
    rts
    
@file_not_found_error:
    .byte "Error: file not found", $0A, $0D, $00 
@file_not_found:
    lda #<@file_not_found_error
    ldx #>@file_not_found_error
    jsr os_print_string 
    rts

event_key:
    rts

event_timer:
    rts




