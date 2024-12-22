
.INCLUDE "std.inc"

.IMPORT putc, getc 
STR_PTR = $8b

.CODE

	lda #%10110000
	sta IO_UART2_CRA

	; MR0A
	lda #%00001001
	sta IO_UART2_MRA

	; MR1B
	lda #%10010011
	sta IO_UART2_MRA
	
	lda #%00000001
	sta IO_UART2_SOPR

	lda #<message
	sta STR_PTR
	lda #>message
	sta STR_PTR+1
	jsr out_string


	lda #$00
	sta IO_GPIO0
loop:
	; jsr getc
	; jsr putc
	jmp loop
	
out_string:
	ldy #$00
@loop:
	lda (STR_PTR), Y
	beq @end
	jsr putc
	iny
	jmp @loop
@end:
	rts

	
.RODATA
message:
	.byte "Hello, Relocator! I'm data...", $00
	; .asciiz "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqqrstuvwxyz"
; .byte "0123456789abcdef"
