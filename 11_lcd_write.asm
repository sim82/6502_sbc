.AUTOIMPORT +
.SEGMENT "VECTORS"
	.WORD $8000

.SEGMENT "IO"
	.BYTE $55
	
.CODE
	lda #$01
	sta $0001
reset:
	jsr check_busy
	lda #$f
	sta $e010

	jsr check_busy
	lda #$1
	sta $e010

	ldx #$0
start:
	jsr check_busy
	lda message, X
	beq reset
	sta $e011
	inx
	jmp start

check_busy:
	ldy #$0
busy_loop:
	lda $e010
	iny
	and #$80
	bne busy_loop
	; lda $0001
	; rol
	; adc #$0
	; sta $0001
	tya
	sta $e000
	; jmp check_busy
; done:
	rts
.RODATA
message:
	.asciiz "Hello, World!"
