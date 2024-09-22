.include "std.inc" ; use at lease the same constants... at some point consolidate into a single bios
.export V_INPT, V_OUTP, V_LOAD, V_SAVE, V_USR, V_INIT
.import putc, getc, uart_init, put_newline, print_hex16
; .export __HEADER_START__
; , __RAM_SIZE__
; , __RAM_START__, __STACKSIZE__, __IBUFFSIZE__

; __IBUFFSIZE__:
; 	.ADDR $0050
; __RAM_START__:
; 	.ADDR $0000
; __STACKSIZE__:
; 	.ADDR $00FF

; __HEADER_START__ = $4000
; __IBUFFSIZE__ = $0080
; __RAM_SIZE__ = $1000
; __RAM_START__ = $0000
; __STACKSIZE__ = $00FF

; IO_UART_IER1 = $e020
; IO_UART_ISR1 = $e020
; IO_UART_CR1  = $e021
; IO_UART_FR1  = $e021
; IO_UART_CSR1 = $e021
; IO_UART_CDR1 = $e022
; IO_UART_ACR1 = $e022
; IO_UART_TDR1 = $e023
; IO_UART_RDR1 = $e023
Smeml             = $79       ; start of mem low byte       (Start-of-Basic)
Smemh             = Smeml+1   ; start of mem high byte      (Start-of-Basic)
Svarl             = $7B       ; start of vars low byte      (Start-of-Variables)
Svarh             = Svarl+1   ; start of vars high byte     (Start-of-Variables)
.CODE

V_INIT:
	jsr uart_init
	rts

V_OUTP:
	jmp putc

V_INPT:
	jmp getc
	
; every byte is sacred...
V_LOAD:
V_USR:
        rts

V_SAVE:
	; lda #$33
	; ldx #$44
	; jsr print_hex16
	lda Smeml
	ldx Smemh
	jsr print_hex16
	jsr put_newline
	lda Svarl
	ldx Svarh
	jsr print_hex16
	jsr put_newline
	rts
      

