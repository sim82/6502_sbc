
.INCLUDE "std.inc"
.INCLUDE "os.inc"
STR_PTR = $8b
TMP1 = STR_PTR + 2

; .BSS
; buf1:
; 	.RES $100
.CODE

	lda #$05
	jsr os_alloc
	jsr os_get_argn
	sta TMP1
	cmp #$01
	beq @read_filename
	ldx #$00
	jsr os_print_dec
	ldy #$00
@arg_loop:
	cpy TMP1
	beq @after_args
	tya
	jsr os_get_arg
	bcc @after_args
	iny
	jmp @arg_loop

@after_args:
	jmp @cat_file	

@read_filename:
	lda #<msg_enter_file
	ldx #>msg_enter_file
	jsr os_print_string

	ldy #$00
@getc_loop:
	jsr os_getc

	cmp #$0d
	beq @leave
	cpy #$20 - 1
	beq @getc_loop
	sta buf1, y
	jsr os_putc
	iny
	jmp @getc_loop
@leave:
	lda #$00
	sta buf1, y
	
	jsr os_putnl
	lda #<buf1
	ldx #>buf1
@cat_file:
	jsr os_fopen
@file_loop:
	jsr os_fgetc
	bcc @eof
	cmp #$0a
	bne @no_lf
	lda #$0d ; pure hate....
	jsr os_putc
	lda #$0a
@no_lf:
	jsr os_putc
	jmp @file_loop

@eof:
	
	rts

; shamelessly exploit the lack of memory protection, and put buffer into code segment *g*
buf1:
	.RES $20
.RODATA
msg_enter_file:
	.byte "enter filename & press enter:", $0d, $0a, $00
