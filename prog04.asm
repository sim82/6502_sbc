.SEGMENT "VECTORS"
	.WORD $8000

.CODE
start:
	lda $100
	sta $e000
	ror a
	sta $100
	jmp start
