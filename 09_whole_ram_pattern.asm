.AUTOIMPORT + 
.SEGMENT "VECTORS"
	.WORD $8000

.ZEROPAGE
	.res $02
pattern_addr:
	.res $2
target_addr:
	.res $2
.CODE
	lda #$55
	sta $e000
	; put patten address into zp for indirect addressing
	lda #< pattern
	sta pattern_addr

	lda #> pattern
	sta pattern_addr + 1

	lda #$0
	sta target_addr
	sta target_addr + 1

	ldx #$03

outer_loop:
	stx $e000
	stx target_addr + 1
	ldy #$00
	clc
	
inner_loop:	
	lda (pattern_addr), Y
	sta (target_addr), Y
	iny
	bne inner_loop
	inx
	cpx #80
	bne outer_loop
	


start:
	ldx #$03

outer_loop2:
	stx $e000
	stx target_addr + 1
	ldy #$00
	clc
	
inner_loop2:	
	lda (target_addr), Y
	sta $e000
	iny
	bne inner_loop2
	inx
	cpx #80
	bne outer_loop2
	
	jmp start

.RODATA
pattern:
.incbin "prog09_pattern.bin"
