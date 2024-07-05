
.export V_INPT, V_OUTP, V_LOAD, V_SAVE, V_USR
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

IO_UART_IER1 = $e020
IO_UART_ISR1 = $e020
IO_UART_CR1  = $e021
IO_UART_FR1  = $e021
IO_UART_CSR1 = $e021
IO_UART_CDR1 = $e022
IO_UART_ACR1 = $e022
IO_UART_TDR1 = $e023
IO_UART_RDR1 = $e023
.CODE
V_OUTP:
	pha
@loop:
	lda IO_UART_ISR1
	and #%01000000
	beq @loop
	pla
	sta IO_UART_TDR1
	rts

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
; every byte is sacred...
V_LOAD:
V_SAVE:
V_USR:
        rts

      
