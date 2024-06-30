.AUTOIMPORT +
.SEGMENT "VECTORS"
	.WORD $8000
.CODE
	clc
	lda #$01
start:
	sta $e000
	rol
	jmp start
	
