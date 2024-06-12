.AUTOIMPORT +
.SEGMENT "VECTORS"
	.WORD $8000

.SEGMENT "IO"
	.BYTE $55
	
NUM1 = $0000
NUM2 = $0002
REM = $0004
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

	jsr check_busy

	lda #$8A
	sta NUM1
	lda #$02
	sta NUM1+1
	lda #$0A
	sta NUM2
	lda #$0
	sta NUM2+1
	jsr div16
	lda NUM1
	sta $e011

	lda #$0b
	sta NUM1
	lda #$35
	sta NUM1+1
	jsr out_dec

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
div16:
	pha
	txa
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
	tax
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
	jsr check_busy
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
	sta $e011
	jmp @revloop
	
@end:
	pla
	rts
.RODATA
message:
	; .asciiz "Hello, World!"
	.asciiz "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqqrstuvwxyz"
