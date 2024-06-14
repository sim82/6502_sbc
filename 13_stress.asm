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
CUR_PAGE = $80

LOW = $03
HIGH = $7f

.CODE
reset:
	; jsr disp_init

	
	ldx #LOW
@page_loop:

	txa
	cmp #HIGH
	beq break_page_loop

	sta CUR_PAGE + 1
	sta IO_GPIO0

	lda #$00
	sta CUR_PAGE
	
	ldy #$00
@byte_loop:
	lda #$00
@pattern_loop:
	sta (CUR_PAGE),Y
	pha
	lda #$00
	pla
	cmp (CUR_PAGE),Y
	bne error
	clc
	adc #$01
	bcc @pattern_loop

	iny
	beq @break_byte_loop
	jmp @byte_loop
@break_byte_loop:
	inx
	jmp @page_loop


break_page_loop:

end_loop: ; end
	nop
	jmp end_loop

error:
	; lda #$55
	; sta IO_GPIO0
	jmp error
	

	; fill work are with 1
		

.RODATA
message:
	.asciiz "Hello, World!"
	; .asciiz "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqqrstuvwxyz"
