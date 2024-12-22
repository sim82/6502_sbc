
.INCLUDE "std.inc"

.IMPORT putc, getc 
STR_PTR = $8b

.CODE

	lda #%00000010
	sta IO_UART2_IMR

	lda #<message
	sta STR_PTR
	lda #>message
	sta STR_PTR+1
	jsr out_string

	lda #<irq
	sta $fdfe
	
	lda #>irq
	sta $fdfe+1

	lda #$00
	sta IO_GPIO0
	cli
loop:
	; jsr getc
	; jsr putc
	jmp loop
	
out_string:
	ldy #$00
@loop:
	lda (STR_PTR), Y
	beq @end
	jsr putc
	iny
	jmp @loop
@end:
	rts

; uart_init2:
; 	; init ti UART
; 	; CRA / CRB - reset tx / rx
; 	lda #%00100000
; 	sta IO_UART2_CRA
; 	sta IO_UART2_CRB
; 	lda #%00110000
; 	sta IO_UART2_CRA
; 	sta IO_UART2_CRB

; 	; CRA - reset MR pointer to 0
; 	lda #%10110000
; 	sta IO_UART2_CRA

; 	; MR0A: select alternative BRG and fifo depth (channel a sets it globally)
; 	lda #%00001001
; 	sta IO_UART2_MRA

; 	; CRB - reset MR pointer to 1
; 	lda #%00010000
; 	sta IO_UART2_CRB

; 	; MR1A / MR1B
; 	lda #%00010011
; 	sta IO_UART2_MRA
; 	sta IO_UART2_MRB

; 	; MR2A / MR1B
;  	lda #%00000111
; 	sta IO_UART2_MRA
; 	sta IO_UART2_MRB

; 	; CSRA / CSRB
; 	lda #%11001100
; 	sta IO_UART2_CSRA
; 	sta IO_UART2_CSRB

; 	; start command to A / B
; 	lda #%00000101
; 	sta IO_UART2_CRA
; 	sta IO_UART2_CRB
; 	rts

irq:
	lda #$ff
	sta IO_GPIO0
	jsr getc
	jsr putc
	rti
	
.RODATA
message:
	.byte "Hello, Relocator! I'm data...", $00
	; .asciiz "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqqrstuvwxyz"
; .byte "0123456789abcdef"
