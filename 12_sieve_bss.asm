; .IMPORT uart_init, div16, put_newline
.import os_putc, os_putnl, os_print_dec, os_print_string
; .INCLUDE "std.inc"

	
; WORK = $1000
; LOW_PRIMES = $1100
; NEXT_START = $1200
; HIGH_PRIMES = $1300
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

.BSS
WORK:
	.RES $100
LOW_PRIMES:
	.RES $40
NEXT_START:
	.RES $40
HIGH_PRIMES:
	.RES $40
DUMMY:
	.RES $40

.CODE
reset:
	; lda WORK
	; lda LOW_PRIMES
	; lda NEXT_START
	; lda HIGH_PRIMES
	; lda DUMMY
	lda #$00
	sta CHECK_SUM
	sta NUM_PRIMES

	; jsr disp_init
	; jsr uart_init
	jsr putc
	
	lda #$00
	tax
	tay
	lda #<message
	ldx #>message
	jsr os_print_string
@after_hello:
	; jsr disp_linefeed


calc_low:
	jsr fill_work
	lda #$00
	sta WORK     ; eliminate 0 & 1
	sta WORK+1

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
	; BAD:
	; pha ; store output (testing)
	
	
	; store prime into LOW_PRIMES array
	ldx NUM_PRIMES
	sta LOW_PRIMES,X
	inc NUM_PRIMES
	tax
	; sta IO_GPIO0
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
	jsr dump_primes_high
	
	jmp calc_high
exit:
	
	lda #<message_done
	ldx #>message_done
	jsr os_print_string
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
	
	ldx #$00
	lda NUM_PRIMES
	jsr os_print_dec
	jsr os_putnl

	; lda #$20
	; lda IO_DISP_DATA
	
@dump_loop:
	ldx #$00
	lda LOW_PRIMES, y
	jsr os_print_dec
	lda #' '
	jsr os_putc

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
	jsr os_putnl
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
	ldx #>message_block
	jsr os_print_string
	lda #$00
	ldx HIGH_BYTE
	jsr os_print_dec
	lda #' '
	jsr os_putc
	
	lda #<message_and
	ldx #>message_and
	jsr os_print_string

	lda #$FF
	ldx HIGH_BYTE
	jsr os_print_dec

	lda #<message_newline
	ldx #>message_newline
	jsr os_print_string

	ldy #$00
	
	; lda #$00
	; sta NUM1+1
	; lda NUM_HIGH
	; sta NUM1
	; jsr out_dec
	; lda #$20
	; lda IO_DISP_DATA
	
@dump_loop:
	ldx HIGH_BYTE
	lda HIGH_PRIMES,y
	jsr os_print_dec
	lda #' '
	jsr os_putc

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
	jsr os_putnl
	jmp @dump_loop
@break:
	pla
	tay
	pla
	tax
	pla
	rts

	; fill work are with 1
fill_work:
	ldx #$00
	lda #$01
@loop:
	sta WORK,X
	inx
	bne @loop

	rts
		

putc:
	jmp os_putc

put_newline:
	jmp os_putnl
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
