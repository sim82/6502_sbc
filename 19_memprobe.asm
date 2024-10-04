.IMPORT uart_init, putc, print_hex8, put_newline

.INCLUDE "std.inc"
.SEGMENT "VECTORS"
	.WORD $0300

	

PAGE_ADDR_LOW = $80
PAGE_ADDR_HI = $81

.CODE


reset:
	jsr uart_init
	lda #$00
	sta PAGE_ADDR_LOW
	lda #$05
	sta PAGE_ADDR_HI
	ldx #$00
	
@loop:
	jsr probe_page
	inc PAGE_ADDR_HI
	
	jmp @loop
 
probe_page:
	lda PAGE_ADDR_HI
	jsr print_hex8
	jsr put_newline

	ldy #$00
@probe_loop:
	txa
	sta (PAGE_ADDR_LOW), y
	cmp (PAGE_ADDR_LOW), y
	bne @probe_loop
	clc
	adc #13
	tax
	iny
	bne @probe_loop
	rts


error:
	lda #'e'
	jsr putc
@loop:
	jmp @loop
	



