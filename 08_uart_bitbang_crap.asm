.AUTOIMPORT + 
.SEGMENT "VECTORS"
	.WORD $8000

.ZEROPAGE
outc_c:
	.res 8
.CODE
start:
	ldx #$04
@loop:
	lda #$1
	sta $e000
	jsr outc_test
	dex
	bne @loop

	ldx #$ff
@del_loop1:
	dex
	bne @del_loop1


	lda #'H'
	jsr outc
	lda #'e'
	jsr outc
	lda #'l'
	jsr outc
	lda #'l'
	jsr outc
	lda #'o'
	jsr outc
	lda #$0a
	jsr outc

	ldx #$ff
@del_loop2:
	dex
	bne @del_loop2
	jmp start

outc_test:
	lda #$0
	sta $e000

	lda #$1
	sta $e000
	lda #$0
	sta $e000
	lda #$1
	sta $e000
	lda #$0
	sta $e000
	lda #$1
	sta $e000
	lda #$0
	sta $e000
	lda #$1
	sta $e000
	lda #$0
	sta $e000
	lda #$1
	sta $e000
	rts
	ldx #$ff

@loop:
	dex
	beq @loop
outc:
	sta <outc_c + 0
	ror
	sta <outc_c + 1
	ror
	sta <outc_c + 2
	ror
	sta <outc_c + 3
	ror
	sta <outc_c + 4
	ror
	sta <outc_c + 5
	ror
	sta <outc_c + 6
	ror
	sta <outc_c + 7
	ror

	; lda #$0
	; sta $e000

	lda <outc_c + 0
	sta $e000
	lda <outc_c + 1
	sta $e000
	lda <outc_c + 2
	sta $e000
	lda <outc_c + 3
	sta $e000
	lda <outc_c + 4
	sta $e000
	lda <outc_c + 5
	sta $e000
	lda <outc_c + 6
	sta $e000
	lda <outc_c + 7
	sta $e000

	lda #$1
	sta $e000

	ldx #$ff

@loop:
	dex
	beq @loop
	rts

	
