.INCLUDE "std.inc"
.EXPORT check_busy, disp_init, div16, out_dec, disp_linefeed
.CODE

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

disp_init:
	lda #$00
	sta DISP_POSX
	sta DISP_POSY

	jsr check_busy
	lda #%00111000      ; 8bit, two row, default font?
	sta IO_DISP_CTRL

	jsr check_busy
	lda #$1             ; clear display
	sta IO_DISP_CTRL

 	jsr check_busy
	lda #$f             ; display on, cursor blink
	sta IO_DISP_CTRL
	rts

check_busy:
	pha
	tya
	pha
	ldy #$0
@loop:
	lda IO_DISP_CTRL
	; iny
	and #$80
	bne @loop
	; tya
	; sta IO_GPIO0

	pla
	tay
	pla
	rts

out_dec:
	pha
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
	jsr check_busy
	sta IO_DISP_DATA
	jmp @revloop
	
@end:
	lda #$20
	jsr check_busy
	sta IO_DISP_DATA
	
	pla
	rts

	
disp_linefeed:
	pha
	jsr check_busy
	lda DISP_POSY
	inc DISP_POSY
	cmp #$0
	bne @line1
@line0:
	lda #$A8  ; start of line1: 64
	sta IO_DISP_CTRL
	pla
	rts
@line1:
	cmp #$1
	bne @line2 
	lda #$94 ; start of line2: 20
	sta IO_DISP_CTRL
	pla
	rts

@line2:
	cmp #$2
	bne @line3
	lda #$D4; start op line3: 84
	sta IO_DISP_CTRL
	pla
	rts

@line3:
	lda #$0
	sta DISP_POSY
	lda #$1 ; init
	sta IO_DISP_CTRL
	pla
	rts
