
.INCLUDE "std.inc"


.CODE
loop:
	jsr low
	jsr high
	jmp loop

low:
	lda #00
	sta IO_GPIO0
	rts

	
high:
	lda #$ff
	sta IO_GPIO0
	rts
	
.byte "0123456789abcdef"
.byte "0123456789abcdef"
.byte "0123456789abcdef"
.byte "0123456789abcdef"
.byte "0123456789abcdef"
.byte "0123456789abcdef"
.byte "0123456789abcdef"
.byte "0123456789abcdef"
.byte "0123456789abcdef"
