
.INCLUDE "std.inc"
.import os_alloc
STR_PTR = $8b

.CODE
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
.byte "0123456789abcdef"
.byte "0123456789abcdef"
.byte "0123456789abcdef"
.byte "0123456789abcdef"
.byte "0123456789abcdef"
.byte "0123456789abcdef"
.byte "0123456789abcdef"
.byte "0123456789abcdef"
.byte "0123456789abcdef"
.byte "0123456789abcdef"
.byte "0123456789abcdef"
.byte "0123456789abcdef"
.byte "0123456789abcdef"
.byte "0123456789abcdef"
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
	; .asciiz "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqqrstuvwxyz"
; .byte "0123456789abcdef"
