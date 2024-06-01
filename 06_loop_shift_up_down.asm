.SEGMENT "VECTORS"
	.WORD $8000

.CODE
start:
	lda #$1
	ldx #$7
loop_down:
	;lda $100
	sta $e000
	rol a
	dex
	bne loop_down
	ldx #$7
loop_up:
	sta $e000
	ror a
	dex
	bne loop_up
	jmp start
