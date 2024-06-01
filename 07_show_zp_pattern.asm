.AUTOIMPORT + 
.SEGMENT "VECTORS"
	.WORD $8000

.ZEROPAGE
	.res $10
pattern_addr:
	.res 2
.CODE
	; put patten address into zp for indirect addressing
	lda #< pattern
	sta pattern_addr

	lda #> pattern
	sta pattern_addr + 1
start:
	ldy #$00 ; indirect address index
	clc
	; load 256 bytes from pattern and write to output 
loop:
	lda (pattern_addr),Y ; load pattern position Y
	sta $e000
	iny
	bcc loop ; break after 256 loops
 	jmp start

.RODATA
pattern:
.incbin "07_pattern.bin"
