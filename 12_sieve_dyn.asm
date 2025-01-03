.IMPORT uart_init, div16, put_newline, putc
.INCLUDE "std.inc"
.import os_alloc
	
; WORK = $1000
; LOW_PRIMES = $1100
; NEXT_START = $1200
; HIGH_PRIMES = $1300
; NUM1 = $0000
; NUM2 = $0002
; REM = $0004
CUR_PRIME = $0080
NUM_PRIMES = $0084
TMP1 = $0086
NUM_HIGH = $0088
HIGH_BYTE = $008a
STR_PTR = $8b

PWORK = $90
PLOW_PRIMES = PWORK + 2
PNEXT_START = PLOW_PRIMES + 2
PHIGH_PRIMES = PNEXT_START + 2

.CODE
reset:
	
	lda #$00
	sta NUM_PRIMES

	sta PWORK 
	sta PLOW_PRIMES
	sta PNEXT_START
	sta PHIGH_PRIMES
	lda #$04
	jsr os_alloc
	sta PWORK + 1
	; ok, this is pathetic...
	sta PLOW_PRIMES + 1
	inc PLOW_PRIMES + 1 ; page 2 in allocated buf
	sta PNEXT_START + 1
	inc PNEXT_START + 1 ; page 3 in allocated buf
	inc PNEXT_START + 1 ; page 3 in allocated buf
	
	sta PHIGH_PRIMES + 1
	inc PHIGH_PRIMES + 1 ; page 4 in allocated buf
	inc PHIGH_PRIMES + 1 ; page 4 in allocated buf
	inc PHIGH_PRIMES + 1 ; page 4 in allocated buf

	; jsr disp_init
	; jsr uart_init
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
	ldy #$00
	
	sta (PWORK), y     ; eliminate 0 & 1
	iny
	sta (PWORK), y

	lda #$02
	sta CUR_PRIME
	; stx LOW_PRIMES ; store 2 directly as first prime
	; sta CUR_PRIME
@elim_loop:
	ldy CUR_PRIME
	beq @break; end on x wrap around

	lda (PWORK),y

	beq @skip ; skip eliminated value

	tya ; a = current (prime * n) to filter forward

	; store prime into LOW_PRIMES array
	ldy NUM_PRIMES
	sta (PLOW_PRIMES), y
	inc NUM_PRIMES
	tay
	; sta IO_GPIO0
	sta CUR_PRIME ; CUR_PRIME = current prime (for * n increments)
@loop:
	clc
	adc CUR_PRIME ; increment prime * n -> prime * (n+1)
	bcs @end ; on carry: moved out of current 256 window

	tay 
	lda #$00
	sta (PWORK),y ; eliminate (write 0 to WORK + prime * n)
	tya
	jmp @loop
@end:
	ldy NUM_PRIMES
	dey
	sta (PNEXT_START), y
	; sta NEXT_START-1,X
@skip:
	inc CUR_PRIME
	jmp @elim_loop
	
@break:
	jsr dump_primes
	; jmp end_loop
	; rts

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

	lda (PLOW_PRIMES),Y
	sta CUR_PRIME
	lda (PNEXT_START),Y
	sty TMP1 ; save y. needs to be used in inner loop
@loop:
	tay
	lda #$00
	sta (PWORK), y
	tya
	clc
	adc CUR_PRIME
	bcc @loop

	ldy TMP1 ; restore y after inner loop
	sta (PNEXT_START), Y
	iny
	jmp @elim_loop
@break:

	; rts
	

gen_high_primes:
	ldy #$00
@loop:
	lda (PWORK),y
	beq @skip

	tya
	tax
	ldy NUM_HIGH
	txa
	sta (PHIGH_PRIMES),y
	iny
	sty NUM_HIGH

	txa
	tay

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
	; rts
	jmp calc_high
exit:

	lda #<message_done
	sta STR_PTR
	lda #>message_done
	sta STR_PTR+1
	jsr out_string
	tsx
	stx IO_GPIO0
	; jmp reset
	rts
@loop:
	jmp @loop

dump_primes:

	pha
	txa
	pha
	tya
	pha
	ldy #$00
	
	lda #$00
	sta NUM1+1
	lda NUM_PRIMES
	sta NUM1
	jsr out_dec
	jsr put_newline

	; lda #$20
	; lda IO_DISP_DATA
	
@dump_loop:
	lda #$00
	sta NUM1+1
	lda (PLOW_PRIMES), y
	sta NUM1
	jsr out_dec
			

	; lda #$00
	; sta NUM1+1
	; lda NEXT_START,X
	; sta NUM1
	; jsr out_dec
	
	iny
	cpy NUM_PRIMES
	beq @break
	tya
	and #$f
	cmp #$f
	bne @dump_loop
	jsr put_newline
	jmp @dump_loop
@break:
	jsr put_newline
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

	ldy #$00
	
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
	lda (PHIGH_PRIMES),y
	sta NUM1
	jsr out_dec
			

	; lda #$00
	; sta NUM1+1
	; lda NEXT_START,X
	; sta NUM1
	; jsr out_dec
	
	iny
	cpy NUM_HIGH
	beq @break
	; txa
	; and #$1
	; cmp #$1
	; bne @dump_loop
	; jsr disp_linefeed
	tya
	and #$f
	cmp #$f
	bne @dump_loop
	jsr put_newline
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
	ldy #$00
	lda #$01
@loop:
	sta (PWORK),y
	iny
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
