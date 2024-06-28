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
	sta IO_UART_CRFR1

	; Bit 7: Select FR = 1
	; Bit 6,5: Num Bits (11 = 8)
	; Bit 4,3: Parity mode (don't care)
	; Bit 2: Parity Enable / Disable (1/0)
	; Bit 1,0: DTR/RTS control (don't care)
	; write FR
	lda #%11100000
	sta IO_UART_CRFR1

	ldx #$00
	lda #$55
@loop:
	lda message, x
	bne @continue
	ldx #$00
	jmp @loop
@continue:
	sta IO_UART_TDRD1
	lda IO_UART_CRFR1
	sta NUM1
	lda #$00
	sta NUM1+1
	jsr check_busy
	jsr out_dec
	inx
	jmp @loop
		

; IO_UART_CRFR1  = $e021
; IO_UART_TDRD1  = $e023
.RODATA
message:
	.byte "Hello, World!", $0A, $0D, $00
	; .asciiz "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqqrstuvwxyz"
