.AUTOIMPORT +
.SEGMENT "VECTORS"
	.WORD $8000

.SEGMENT "IO"
	.BYTE $55
	
.CODE
	lda #$01
	sta $0001
reset:
	lda #$f
	sta $e011
	lda #$1
	sta $e011
	ldx #$0
start:
	lda message, X
	beq reset
	sta $e012
	inx
	lda $0001
	rol
	adc #$0
	sta $0001
	sta $e000
	jmp start
.RODATA
message:
	.asciiz "Hello, World!"
