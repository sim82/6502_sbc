
.INCLUDE "std.inc"
.EXPORT uart_init, putc, getc, fputc, fgetc, fgetc_nonblocking, print_hex16, print_hex8, put_newline, fpurge
.CODE

uart_init:
	; init ti UART
	; CRA / CRB - reset tx / rx
	lda #%00100000
	sta IO_UART2_CRA
	sta IO_UART2_CRB
	lda #%00110000
	sta IO_UART2_CRA
	sta IO_UART2_CRB

	; CRA - reset MR pointer to 0
	lda #%10110000
	sta IO_UART2_CRA

	; MR0A: select alternative BRG and fifo depth (channel a sets it globally)
	lda #%00001001
	sta IO_UART2_MRA

	; CRB - reset MR pointer to 1
	lda #%00010000
	sta IO_UART2_CRB

	; MR1A / MR1B
	lda #%00010011
	sta IO_UART2_MRA
	sta IO_UART2_MRB

	; MR2A / MR1B
 	lda #%00000111
	sta IO_UART2_MRA
	sta IO_UART2_MRB

	; CSRA / CSRB
	lda #%11001100
	sta IO_UART2_CSRA
	sta IO_UART2_CSRB

	; start command to A / B
	lda #%00000101
	sta IO_UART2_CRA
	sta IO_UART2_CRB
	; jsr uartaux_init
	rts


; uartaux_init:
; 	; init ti UART
; 	; CRA / CRB - reset tx / rx
; 	lda #%00100000
; 	sta IO_UARTAUX_CRA
; 	sta IO_UARTAUX_CRB
; 	lda #%00110000
; 	sta IO_UARTAUX_CRA
; 	sta IO_UARTAUX_CRB

; 	; CRA - reset MR pointer to 0
; 	lda #%10110000
; 	sta IO_UARTAUX_CRA

; 	; MR0A: select alternative BRG and fifo depth (channel a sets it globally)
; 	lda #%00001001
; 	sta IO_UARTAUX_MRA

; 	; CRB - reset MR pointer to 1
; 	lda #%00010000
; 	sta IO_UARTAUX_CRB

; 	; MR1A / MR1B
; 	lda #%00010011
; 	sta IO_UARTAUX_MRA
; 	sta IO_UARTAUX_MRB

; 	; MR2A / MR1B
;  	lda #%00000111
; 	sta IO_UARTAUX_MRA
; 	sta IO_UARTAUX_MRB

; 	; CSRA / CSRB
; 	lda #%11001100
; 	sta IO_UARTAUX_CSRA
; 	sta IO_UARTAUX_CSRB

; 	; start command to A / B
; 	lda #%00000101
; 	sta IO_UARTAUX_CRA
; 	sta IO_UARTAUX_CRB
; 	rts

putc:
; V_OUTP:
	pha
@loop:
	lda IO_UART2_SRA
	and #%00000100
	beq @loop
	pla
	sta IO_UART2_FIFOA
	rts

getc:
; V_INPT:
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

fputc:
	pha
@loop:
	lda IO_UART2_SRB
	and #%00000100
	beq @loop
	pla
	sta IO_UART2_FIFOB
	; NOTE: make sure that this function preserves the state of the zero flag according to the written byte!
	; some code depends on this behavior.
	rts

fgetc:
	jsr fgetc_nonblocking
	bcc fgetc
	rts

fgetc_nonblocking:
@loop:
	; check transmit data register empty
	lda IO_UART2_SRB
	; sta IO_GPIO0
	and #%00000001
	beq @no_keypress
	and #%00010000
	bne @error
	lda IO_UART2_FIFOB
        sec
	rts

@no_keypress:
        clc
	rts
@error:
	lda #%01000000
	sta IO_UART2_CRB
	lda DISP_POSX
	sta IO_GPIO0
	inc
	sta DISP_POSX
	jmp fgetc_nonblocking

fpurge:
; purge any channel2 input buffer
	jsr fgetc_nonblocking
	bcc @end
	lda #'X'
	jsr putc
	; sta IO_GPIO0
	; jsr putc
	jmp fpurge

@end:
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


