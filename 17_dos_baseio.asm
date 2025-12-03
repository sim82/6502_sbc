
.import putc, fputc, fpurge, open_file_nonpaged, fgetc_nonpaged, getc, fgetc_block, open_file_c1block
.export print_message, decode_nibble, decode_nibble_high, print_dec, getc_blocking, get_arg_hex
.include "17_dos.inc"
.code

; low in a, high in x,
print_message:
	sta zp_ptr
	stx zp_ptr + 1
	tya
	pha
	ldy #$00
@loop:
	lda (zp_ptr), y
	beq @end
	jsr putc
	iny
	jmp @loop
@end:
	pla
	tay
	rts

get_arg_hex:
	phx
	lda (zp_ptr), y
	jsr decode_nibble_high
	sta zp_a_temp

	iny
	lda (zp_ptr), y
	jsr decode_nibble
	ora zp_a_temp
	sta zp_a_temp
	plx
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

print_dec:
	pha
	phx
	sta NUM1
	stx NUM1 + 1
	lda #$0
	pha
@loop:
	lda #$0A
	sta NUM2
	lda #$0
	sta NUM2+1

	jsr div16
	; jsr check_busy
	lda REM
	clc
	adc #$30
	; sta $e011
	pha
	lda NUM1
	ora NUM1+1
	bne @loop
@revloop:
	pla
	beq @end
	jsr putc
	jmp @revloop
	
@end:
	; lda #$20
	; jsr putc
	
	plx
	pla
	rts

div16:
	pha
	txa
	pha
	tya 
	pha
	lda #$0
	sta REM
	sta REM+1
	ldx #16
@l1:
	asl NUM1
	rol NUM1+1
	rol REM
	rol REM+1
	lda REM
	sec ; trial subtraction
	sbc NUM2
	tay
	lda REM+1
	sbc NUM2+1
	bcc @l2 ; did subtraction succeed
	sta REM+1
	sty REM
	inc NUM1
@l2:
	dex
	bne @l1
	pla
	tay
	pla
	tax
	pla
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

getc_blocking:
	jsr getc
	bcc getc_blocking
	rts
