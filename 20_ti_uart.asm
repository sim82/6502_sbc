.IMPORT uart_init, print_hex8, put_newline

.INCLUDE "std.inc"
.SEGMENT "VECTORS"
	.WORD $8000

	

PAGE_ADDR_LOW = $80
PAGE_ADDR_HI = $81

.CODE


reset:
	; jsr uart_init

	; jsr put_newline

	; CRA - reset MR pointer
	lda #%10110000
	sta IO_UART2_CRA
	; sta $fe32
	; jsr dly

	; MR0A
	lda #%00001001
	sta IO_UART2_MRA
	; sta $fe30


	; MR1A
	lda #%00010011
	sta IO_UART2_MRA
	; sta $fe30

	; MR2A
	lda #%00000111
	sta IO_UART2_MRA
	; sta $fe30

	; CSRA
	; lda #%01100110
	; lda #%10111011
	lda #%11001100
	sta IO_UART2_CSRA
	; sta $fe31


	lda #%00000101
	sta IO_UART2_CRA
	; sta $fe32
	; CRA
	; reset MR pointer to 0x0
	; lda #%10110000
	; lda #%10110101
	; sta $fe32
	; jsr dly

	; lda $fe30
	; jsr print_hex8
	; lda #' '
	; jsr putc

	; lda $fe30
	; jsr print_hex8
	; lda #' '
	; jsr putc

	; lda $fe30
	; jsr print_hex8
	; lda #' '
	; jsr putc

	; ; lda $fe30
	; ; jsr print_hex8
	; ; lda #' '
	; ; jsr putc
	; jsr put_newline

	

@loop:

	jsr getc
	bcc @loop
	jsr putc
	jmp @loop

@waitchar:
	lda IO_UART2_SRA
	and #%00000001
	beq @waitchar
	lda IO_UART2_FIFOA
	tax

@waitfull:
	; sta IO_UART_TDR1
	lda IO_UART2_SRA
	and #%00000100
	beq @waitfull

	; jsr dly
	; jsr print_hex8
	; lda #' '
	; jsr putc

	; lda #'a'
	txa
	; inx
	sta IO_UART2_FIFOA

	; jsr dly
	jmp @loop


loop:
	lda  #%10000000
	; lda  #%11111111
	sta $fe3e
	jsr dly
	lda  #%10000000
	; lda  #%11111111
	sta $fe3f
	jmp loop
	
dly:
	ldy $ff
@loop:
	dey
	bne @loop
	rts



 

putc:
V_OUTP:
	pha
@loop:
	lda IO_UART2_SRA
	and #%00000100
	beq @loop
	pla
	sta IO_UART2_FIFOA
	rts

getc:
V_INPT:
@loop:
	; check transmit data register empty
	lda IO_UART2_SRA
	and #%00000001
	beq @no_keypress
	lda IO_UART2_FIFOA
        sec
	rts

@no_keypress:
        clc
	rts
