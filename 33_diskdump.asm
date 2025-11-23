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
ptr0: 
ptr0l:.res $1
ptr0h:.res $1
temp: .res $1
startblock: .res $1
endblock: .res $1

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

    ; expecting arguments: dd <filename> <src start block> <src end block> <dest lba low>
    jsr os_get_argn
    sta ARG0
    jsr os_dbg_byte
    cmp #$05
    beq @no_missing_arg

    print_inline "Error: missing filename argument"
    rts

@no_missing_arg:
    ; get first argument (filename)
    lda #$01
    jsr os_get_arg

    ; open file for reading
    jsr os_fopen
    bcs @file_found

    print_inline "Error: file not found"
    rts
@file_found:

    ; get 2nd argument (src start block)
    lda #$02
    jsr os_get_arg
    jsr get_arg_hex

    ; use hex value read from arg as LBA low
    ; lda #$71
    ldx #$00
    ldy #$00
    jsr os_ide_set_lba
    lda #$00
    sta cur_pos

    ; get 3rd and 4th argument (src end block):w
    lda #$03
    jsr os_get_arg
    jsr get_arg_hex
    sta startblock
    lda #$04
    jsr os_get_arg
    jsr get_arg_hex
    sta endblock



    ; loop over blocks until eof, writing each to ide
@block_loop:
    ; compare if cur_pos is >= $10 and cur_pos < $20 and only call os_id_write_block if true
    lda cur_pos
    sta ARG0
    cmp startblock
    ; cmp #$e0
    bcc @no_write
    lda cur_pos
    cmp endblock
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



event_key:
    rts

event_timer:
    rts

get_arg_hex:
    sta ptr0l
    stx ptr0h
    ldy #$00
    lda (ptr0), y
    jsr decode_nibble_high
    sta temp

    ldy #$01
    lda (ptr0), y
    jsr decode_nibble
    ora temp
    sta temp
    sta ARG0
    jsr os_dbg_byte
    rts

decode_nibble_high:
	jsr decode_nibble
	bcs @exit
	asl
	asl
	asl
	asl
@exit:
	rts
decode_nibble:
	; sta IO_DISP_DATA
	cmp #'0'
	bmi @bad_char

	cmp #':'
	bpl @high
	sec
	sbc #'0'
	; pha
	; lda #$00
	; sta NUM1+1
	; pla
	; sta NUM1
	; jsr out_dec
	clc
	rts

@high:
	cmp #'a'
	bmi @bad_char
	cmp #'g'
	bpl @bad_char
	sec
	sbc #('a' - 10)
	clc
	rts

@bad_char:
	sec
	rts

error:
	lda #$55
	sta IO_GPIO0
	jmp error

