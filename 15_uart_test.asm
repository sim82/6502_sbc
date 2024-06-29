.AUTOIMPORT +
.INCLUDE "std.inc"
.SEGMENT "VECTORS"
	.WORD $8000

.SEGMENT "IO"
	.BYTE $55
	

.CODE

	jsr disp_init
	
	lda #$00
	tax
	tay
hello:
	jsr check_busy
	lda message, X
	beq @after_hello
	sta IO_DISP_DATA
	inx
	jmp hello
@after_hello:
	jsr disp_linefeed

	; Bit 7: Select CR = 0
	; Bit 6: CDR/ACR (don't care)
	; Bit 5: Num stop bits (0=1, 1-2)
	; Bit 4: Echo mode (0=disabled, 1=enabled)
	; Bit 3-0: baud divisor (1110 = 3840)
	; write CR
	lda #%00001110
	sta IO_UART_CR1

	; Bit 7: Select FR = 1
	; Bit 6,5: Num Bits (11 = 8)
	; Bit 4,3: Parity mode (don't care)
	; Bit 2: Parity Enable / Disable (1/0)
	; Bit 1,0: DTR/RTS control (don't care)
	; write FR
	lda #%11100000
	sta IO_UART_FR1

	lda #%11000001
	sta IO_UART_IER1

	ldx #$00
	lda #$55
@loop:
	; check transmit data register empty
	lda IO_UART_ISR1
	; sta IO_GPIO0

	; and #%00000001
	; beq @loop
	; lda IO_UART_RDR1
	; sta IO_GPIO0
	; jmp @loop

	
	tay
	and #%00000001
	beq @write
	lda IO_UART_RDR1
	jsr check_busy
	sta IO_DISP_DATA
@write:
	tya
	and #%01000000
	; sty IO_GPIO0
	beq @loop
	lda #$00
	sta IO_GPIO0
	lda message, x
	bne @continue
	ldx #$00
	jmp @loop
@continue:
	sta IO_UART_TDR1
	inx
	lda #$FF
	sta IO_GPIO0
	jmp @loop
		

; IO_UART_CRFR1  = $e021
; IO_UART_TDRD1  = $e023
.RODATA
message:
	.byte "Hello, World!", $0D, $0A, $00
	; .asciiz "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqqrstuvwxyz"
