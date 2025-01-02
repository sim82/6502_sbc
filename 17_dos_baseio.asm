
.import putc
.export print_message, decode_nibble, decode_nibble_high
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

decode_nibble_high:
	jsr decode_nibble
	bcc @exit
	asl
	asl
	asl
	asl
	sec
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
	sec
	rts

@high:
	cmp #'a'
	bmi @bad_char
	cmp #'g'
	bpl @bad_char
	sec
	sbc #('a' - 10)
	sec
	rts

@bad_char:
	clc
	rts
