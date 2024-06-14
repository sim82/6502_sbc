.AUTOIMPORT +
.INCLUDE "std.inc"
.SEGMENT "VECTORS"
	.WORD $8000

.SEGMENT "IO"
	.BYTE $55
	
WORK = $1000
; NUM1 = $0000
; NUM2 = $0002
; REM = $0004
CUR_PRIME = $0080
CHECK_SUM = $0082
NUM_PRIMES = $0084

.CODE
	lda #$00
	sta CHECK_SUM
	sta NUM_PRIMES

reset:
	jsr disp_init
	
; 	; display addressing debug
; 	ldx #80
; 	lda #$30
; @test_loop:
; 	; pha
; 	; txa
; 	; ora #$80
; 	; jsr check_busy
; 	; sta IO_DISP_CTRL
; 	; jsr check_busy
; 	; pla
; 	sta IO_DISP_DATA
; 	clc
; 	adc #1
; 	cmp #$3A
; 	bne @skip
; 	lda #$30
; @skip: 
; 	ldy #$FF
; @delay:
; 	dey
; 	bne @delay
; 	jsr check_busy
; 	pha
; 	lda IO_DISP_CTRL
; 	sta IO_GPIO0
; 	pla
; 	dex
; 	bne @test_loop
	
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
	jsr fill_work

	lda #$00

	sta WORK     ; eliminate 0 & 1
	sta WORK+1
	pha ; sentiel for output

	ldx #$02
	; sta CUR_PRIME
elim_loop:
	beq dump_stack; end on x wrap around
	lda WORK,X

	beq @skip ; skip eliminated value

	txa ; a = current (prime * n) to filter forward
	clc
	adc CHECK_SUM
	sta CHECK_SUM
	inc NUM_PRIMES

	txa ; restore a	
	pha ; store output (testing)
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
@skip:
@end:
	inx
	jmp elim_loop
	

dump_stack:
	ldx #$01
	lda CHECK_SUM
	sta IO_GPIO0
@dump_loop:
	lda #$00
	sta NUM1+1
	pla
	; txa
	beq end_loop
	sta IO_GPIO0
	sta NUM1
	; jsr out_dec
	; jsr check_busy
	; lda #$20
	; lda IO_DISP_DATA

	inx
	; txa
	; and #$3
	; cmp #$3
	; bne @dump_loop
	; jsr disp_linefeed
	jmp @dump_loop

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

	lda #$30
	sta IO_DISP_DATA
	rts
		

.RODATA
message:
	.asciiz "Hello, World!"
	; .asciiz "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqqrstuvwxyz"
