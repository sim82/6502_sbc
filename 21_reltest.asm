
.INCLUDE "std.inc"
.import os_alloc, os_putc, os_getc, os_fopen, os_fgetc, os_print_string, os_putnl, os_get_argn, os_get_arg, os_print_dec
STR_PTR = $8b
TMP1 = STR_PTR + 2

.BSS
buf1:
	.RES $100
buf2:
	.RES $100
.CODE

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
	sta IO_GPIO0
	; jsr os_print_string
	; jsr os_putnl
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
	
	lda buf1
	lda buf2
	lda #5
	jsr os_alloc
	lda #<message
	sta STR_PTR
	lda #>message
	sta STR_PTR+1
	jsr out_string
	rts
	jmp loop
.byte "0123456789abcdef"
.byte "0123456789abcdef"
.byte "0123456789abcdef"
.byte "0123456789abcdef"
.byte "0123456789abcdef"
loop:
	jsr low
	jsr high
	jmp loop

.byte "0123456789abcdef"
.byte "012344678"
; .byte "0123456789abcdef"
; .byte "0123456789abcdef"
; .byte "0123456789abcdef"
; .byte "0123456789abcdef"
; .byte "0123456789abcdef"
; .byte "0123456789abcdef"
; .byte "0123456789abcdef"
; .byte "0123456789abcdef"
; .byte "0123456789abcdef"
; .byte "0123456789abcdef"
; .byte "0123456789abcdef"
; .byte "0123456789abcdef"
; .byte "0123456789abcdef"
.byte "0123456789abcdef"
low:
	lda #00
	sta IO_GPIO0
	rts

	
.byte "0123456789abcdef"
.byte "0123456789abcdef"
.byte "0123456789abcdef"
; .byte "0123456789abcdef"
; .byte "0123456789abcdef"
high:
	lda #$ff
	sta IO_GPIO0
	rts
	
out_string:
	ldy #$00
@loop:
	lda (STR_PTR), Y
	beq @end
	; jsr putc
	iny
	jmp @loop
@end:
	rts

.RODATA
message:
	.byte "Hello, Relocator! I'm data...", $00
msg_enter_file:
	.byte "enter filename & press enter:", $0d, $0a, $00

filename:
	.byte "tt", $00
	; .asciiz "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqqrstuvwxyz"
; .byte "0123456789abcdef"
