.IMPORT uart_init, putc, print_hex8, put_newline

.INCLUDE "std.inc"
.SEGMENT "VECTORS"
	.WORD $0300

	

PAGE_ADDR_LOW = $80
PAGE_ADDR_HI = $81

.CODE


reset:
	jsr uart_init

	jsr put_newline

	; lda #%00101010
	; sta $fe32
	; jsr dly
	; lda #%00110000
	; sta $fe32
	; jsr dly
	; lda #%01000000
	; sta $fe32
	; jsr dly
	
	; lda #%01010000
	; sta $fe32
	; jsr dly

	; CRA - reset MR pointer
	; lda #%10110000
	; sta $fe32
	; jsr dly

	; ; MR0A
	; lda #%00001000
	; sta $fe30

	; ; CRA - reset MR pointer
	; lda #%00010000
	; sta $fe32
	; jsr dly

	; MR1A
	lda #%00010011
	sta $fe30

	; MR2A
	lda #%00000111
	sta $fe30

	; CSRA
	lda #%11001100
	sta $fe31

	; ; ACR
	; lda #%00000000
	; ; lda #%01100000
	; sta $fe34
	; ; IMR
	; lda #%00000000
	; sta $fe35
	; sta $fe36
	; sta $fe37
	; sta $fe3d

	; CRA
	; reset MR pointer to 0x0
	; lda #%10110000
	; sta $fe32

	; ; MR0A
	; lda #%00001000
	; sta $fe30

	; ; MR1A
	; lda #%00010011
	; sta $fe30

	; ; MR2A
	; lda #%00000111
	; sta $fe30

	; MR2A
	; lda $%00000000
	; sta $fe30

	; CRA
	; reset MR pointer to 0x0
	; lda #%10110000
	lda #%00010000
	sta $fe32
	jsr dly

	lda $fe30
	jsr print_hex8
	lda #' '
	jsr putc

	lda $fe30
	jsr print_hex8
	lda #' '
	jsr putc

	lda $fe30
	jsr print_hex8
	lda #' '
	jsr putc

	; lda $fe30
	; jsr print_hex8
	; lda #' '
	; jsr putc
	jsr put_newline

	; CRA
	lda #%00000100
	sta $fe32
	

@loop:

	; sta IO_UART_TDR1
	; lda $fe31
	; jsr dly
	; jsr print_hex8
	; lda #' '
	; jsr putc

	; lda #'a'
	txa
	inx
	sta $fe33

	jsr dly
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



 
