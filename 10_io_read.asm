.AUTOIMPORT +
.SEGMENT "VECTORS"
	.WORD $8000

.SEGMENT "IO"
	.BYTE $55
	
.CODE
start:
	lda $e000
	sta $e000
	jmp start
.RODATA
