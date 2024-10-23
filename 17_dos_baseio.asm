
.import putc
.export print_message
.include "17_dos.inc"
.code

; low in a, high in x,
print_message:
	sta ZP_PTR
	stx ZP_PTR + 1
	ldy #$00
@loop:
	lda (ZP_PTR), y
	beq @end
	jsr putc
	iny
	jmp @loop
@end:
	rts

