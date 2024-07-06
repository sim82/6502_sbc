.include "std.inc" ; use at lease the same constants... at some point consolidate into a single bios
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
V_USR:
        rts

V_SAVE:
	; lda #$33
	; ldx #$44
	; jsr print_hex16
	lda Smeml
	ldx Smemh
	jsr print_hex16
	jsr print_newline
	lda Svarl
	ldx Svarh
	jsr print_hex16
	jsr print_newline
	rts
      
print_newline:
	lda #$0A
	jsr V_OUTP
	lda #$0D
	jsr V_OUTP
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
	jsr V_OUTP
	rts
	

