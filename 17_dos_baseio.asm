
.import putc, fputc, fpurge, open_file_nonpaged, getc
.export print_message, decode_nibble, decode_nibble_high, print_dec, file_open_raw, getc_blocking
.include "17_dos.inc"
.code


file_open_raw:
	sta ZP_PTR
	stx ZP_PTR + 1
	tya
	pha
	jsr fpurge
	lda #'r'
	jsr fputc
	ldy #$00
@send_filename_loop:
	lda (ZP_PTR), y
	jsr fputc
	beq @end_of_filename ; meh, it is a bit of a stretch to expect fputc to preserve zero flag...
	iny
	jmp @send_filename_loop
@end_of_filename:
	jsr open_file_nonpaged
	pla
	tya
	rts
; low in a, high in x,
print_message:
	sta ZP_PTR
	stx ZP_PTR + 1
	tya
	pha
	ldy #$00
@loop:
	lda (ZP_PTR), y
	beq @end
	jsr putc
	iny
	jmp @loop
@end:
	pla
	tay
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
