.AUTOIMPORT +
.SEGMENT "VECTORS"
	.WORD $8000

.SEGMENT "IO"
	.BYTE $55
	
.CODE
reset:
	lda #$f
	sta $e001
	lda #$1
	sta $e001
	ldx #$0
start:
	lda message, X
	beq reset
	sta $e002
	inx
	jmp start
.RODATA
message:
	.asciiz "Hello, World!"
