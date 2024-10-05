.IMPORT uart_init, div16, put_newline, putc
.INCLUDE "std.inc"

	
WORK = $1000
LOW_PRIMES = $1100
NEXT_START = $1200
HIGH_PRIMES = $1300
; NUM1 = $0000
; NUM2 = $0002
; REM = $0004
CUR_PRIME = $0080
CHECK_SUM = $0082
NUM_PRIMES = $0084
TMP1 = $0086
NUM_HIGH = $0088
HIGH_BYTE = $008a
STR_PTR = $8b

.CODE
reset:
	lda #$00
	sta CHECK_SUM
	sta NUM_PRIMES

	; jsr disp_init
	jsr uart_init
	jsr putc
	
	lda #$00
	tax
	tay
	lda #<message
	sta STR_PTR
	lda #>message
	sta STR_PTR+1
	jsr out_string
@after_hello:
	; jsr disp_linefeed


calc_low:
	jsr fill_work
	lda #$00
	sta WORK     ; eliminate 0 & 1
	sta WORK+1
	lda #$FF
	pha ; sentiel for output

	ldx #$02
	; stx LOW_PRIMES ; store 2 directly as first prime
	; sta CUR_PRIME
@elim_loop:
	beq @break; end on x wrap around
	lda WORK,X

	beq @skip ; skip eliminated value

	txa ; a = current (prime * n) to filter forward
	clc
	adc CHECK_SUM
	sta CHECK_SUM

	txa ; restore a	
	pha ; store output (testing)
	
	
	; store prime into LOW_PRIMES array
	ldx NUM_PRIMES
	sta LOW_PRIMES,X
	inc NUM_PRIMES
	tax
	sta IO_GPIO0
	sta CUR_PRIME ; CUR_PRIME = current prime (for * n increments)
@loop:
	clc
	adc CUR_PRIME ; increment prime * n -> prime * (n+1)
	bcs @end ; on carry: moved out of current 256 window

	tay ; use Y to address value on WORK area (for elimination)
	pha ; eliminate (write 0)
	lda #$00
	sta WORK,Y
	pla
	jmp @loop
@end:
	stx TMP1
	ldx NUM_PRIMES
	sta NEXT_START-1,X
	ldx TMP1
@skip:
	inx
	jmp @elim_loop
	
@break:
	jsr dump_primes
	; jmp end_loop

	lda #$00
	sta HIGH_BYTE
calc_high:
	lda #$00
	sta NUM_HIGH
	inc HIGH_BYTE
	beq exit
	jsr fill_work
	ldy #$00
	
@elim_loop:
	cpy NUM_PRIMES
	beq @break

	lda LOW_PRIMES,Y
	sta CUR_PRIME
	lda NEXT_START,Y
@loop:
	tax
	lda #$00
	sta WORK, X
	txa
	clc
	adc CUR_PRIME
	bcc @loop
	sta NEXT_START, Y

	iny
	jmp @elim_loop
@break:

	

gen_high_primes:
	ldy #$00
@loop:
	lda WORK,Y
	beq @skip

	ldx NUM_HIGH
	tya
	sta HIGH_PRIMES,X
	inx
	stx NUM_HIGH

@skip:
	iny
	beq @break
	jmp @loop
@break:
	; lda #<message2
	; sta STR_PTR
	; lda #>message2
	; sta STR_PTR+1
	; jsr out_string
	jsr dump_primes_high
	jmp calc_high
exit:

	lda #<message_done
	sta STR_PTR
	lda #>message_done
	sta STR_PTR+1
	jsr out_string
	jmp reset
@loop:
	jmp @loop

dump_primes:
	pha
	txa
	pha
	tya
	pha
	ldx #$00
	
	lda #$00
	sta NUM1+1
	lda NUM_PRIMES
	sta NUM1
	jsr out_dec
	; lda #$20
	; lda IO_DISP_DATA
	
@dump_loop:
	lda #$00
	sta NUM1+1
	lda LOW_PRIMES,X
	sta NUM1
	jsr out_dec
			

	lda #$00
	sta NUM1+1
	lda NEXT_START,X
	sta NUM1
	jsr out_dec
	
	inx
	cpx NUM_PRIMES
	beq @break
	txa
	and #$1
	cmp #$1
	bne @dump_loop
	; jsr disp_linefeed
	jsr put_newline
	jmp @dump_loop
@break:
	pla
	tay
	pla
	tax
	pla
	rts

dump_primes_high:
	pha
	txa
	pha
	tya
	pha

	lda #<message_block
	sta STR_PTR
	lda #>message_block
	sta STR_PTR+1
	jsr out_string
	lda #$00
	sta NUM1
	lda HIGH_BYTE
	sta NUM1+1
	jsr out_dec
	
	lda #<message_and
	sta STR_PTR
	lda #>message_and
	sta STR_PTR+1
	jsr out_string

	lda #$FF
	sta NUM1
	lda HIGH_BYTE
	sta NUM1+1
	jsr out_dec

	lda #<message_newline
	sta STR_PTR
	lda #>message_newline
	sta STR_PTR+1
	jsr out_string

	ldx #$00
	
	; lda #$00
	; sta NUM1+1
	; lda NUM_HIGH
	; sta NUM1
	; jsr out_dec
	; lda #$20
	; lda IO_DISP_DATA
	
@dump_loop:
	lda HIGH_BYTE
	sta NUM1+1
	lda HIGH_PRIMES,X
	sta NUM1
	jsr out_dec
			

	; lda #$00
	; sta NUM1+1
	; lda NEXT_START,X
	; sta NUM1
	; jsr out_dec
	
	inx
	cpx NUM_HIGH
	beq @break
	; txa
	; and #$1
	; cmp #$1
	; bne @dump_loop
	; jsr disp_linefeed
	jmp @dump_loop
@break:
	pla
	tay
	pla
	tax
	pla
	rts

out_dec:
	pha
	lda #$0
	pha
@loop:
	lda #$0A
	sta NUM2
	lda #$0
	sta NUM2+1

	jsr div16
	; jsr check_busy
	lda REM
	clc
	adc #$30
	; sta $e011
	pha
	lda NUM1
	ora NUM1+1
	bne @loop
@revloop:
	pla
	beq @end
	jsr putc
	jmp @revloop
	
@end:
	lda #$20
	jsr putc
	
	pla
	rts
; uart_write_blocking:
; 	pha
; @loop:
; 	lda IO_UART_ISR1
; 	and #%01000000
; 	beq @loop
; 	pla
; 	sta IO_UART_TDR1
; 	rts

end_loop: ; end
	nop
	jmp end_loop

	; fill work are with 1
fill_work:
	ldx #$00
	lda #$01
@loop:
	sta WORK,X
	inx
	bne @loop

	rts
		
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

.RODATA
message:
	.byte $0D, $0A
	.byte "Calc Primes..." 
message_newline:
	.byte $0D, $0A, $00
message_block:
	.byte $0D, $0A
	.byte "Primes between ", $00
message_and:
	.byte "and ", $00
	
message_done:
	.byte $0D, $0A
	.byte "Done.", $0D, $0A, $00
	; .asciiz "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqqrstuvwxyz"
