
.INCLUDE "std.inc"
.EXPORT uart_init, putc, getc, putc2, getc2, getc2_nonblocking, print_hex16, print_hex8, put_newline
.CODE

uart_init:
	; init uart channel 2
	; Bit 7: Select CR = 0
	; Bit 6: CDR/ACR (don't care)
	; Bit 5: Num stop bits (0=1, 1-2)
	; Bit 4: Echo mode (0=disabled, 1=enabled)
	; Bit 3-0: baud divisor (1110 = 3840)
	; write CR
	lda #%00001110
	sta IO_UART_CR1
	sta IO_UART_CR2

	; Bit 7: Select FR = 1
	; Bit 6,5: Num Bits (11 = 8)
	; Bit 4,3: Parity mode (don't care)
	; Bit 2: Parity Enable / Disable (1/0)
	; Bit 1,0: DTR/RTS control (don't care)
	; write FR
	lda #%11100000
	sta IO_UART_FR1
	sta IO_UART_FR2

	lda #%11000001
	sta IO_UART_IER1
	sta IO_UART_IER2
	rts


putc:
V_OUTP:
	pha
@loop:
	lda IO_UART_ISR1
	and #%01000000
	beq @loop
	pla
	sta IO_UART_TDR1
	rts

getc:
V_INPT:
@loop:
	; check transmit data register empty
	lda IO_UART_ISR1
	and #%00000001
	beq @no_keypress
	lda IO_UART_RDR1
        sec
	rts

@no_keypress:
        clc
	rts


putc2:
	pha
@loop:
	lda IO_UART_ISR2
	and #%01000000
	beq @loop
	pla
	sta IO_UART_TDR2
	rts

getc2:
	jsr getc2_nonblocking
	bcc getc2
	rts

getc2_nonblocking:
@loop:
	; check transmit data register empty
	lda IO_UART_ISR2
	and #%00000001
	beq @no_keypress
	lda IO_UART_RDR2
        sec
	rts

@no_keypress:
        clc
	rts

purge_channel2_input:
; purge any channel2 input buffer
	jsr getc2_nonblocking
	bcs purge_channel2_input
	rts

put_newline:
	lda #$0a
	jsr putc
	lda #$0d
	jsr putc
	rts


; low in a, high in x
print_hex16:
	pha
	txa
	jsr print_hex8
	pla
	jsr print_hex8
	rts

; arg in a
print_hex8:
	pha
	jsr print_hex4_high
	pla
	jsr print_hex4
	rts

print_hex4_high:
	lsr
	lsr
	lsr
	lsr
print_hex4:
	and #$f
	cmp #10
	bcs @in_a_to_f_range
	clc
	adc #'0'
	jmp @output
@in_a_to_f_range:
	; cmp $16
	; bmi @error
	; adc #('a' - 10)
	clc
	adc #($61 - $a)
	jmp @output
; @error:
; 	lda #'X'
@output:
	jsr putc
	rts


