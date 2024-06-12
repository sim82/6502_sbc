.AUTOIMPORT +
.INCLUDE "std.inc"
.SEGMENT "VECTORS"
	.WORD $8000

.SEGMENT "IO"
	.BYTE $55
	
; NUM1 = $0000
; NUM2 = $0002
; REM = $0004
.CODE
	lda #$01
	sta $0001
reset:
	jsr disp_init
	jsr check_busy

; @loop:
; 	lda #$65
; 	sta IO_DISP_DATA
; 	jmp @loop
	

	lda #$8A
	sta NUM1
	lda #$02
	sta NUM1+1
	lda #$0A
	sta NUM2
	lda #$0
	sta NUM2+1
	jsr div16
	lda NUM1
	sta $e011

	lda #$0b
	sta NUM1
	lda #$35
	sta NUM1+1
	jsr out_dec
	jsr disp_linefeed

	ldx #$0
@hello:
	jsr check_busy
	lda message, X
	beq @out
	sta $e011
	inx
	jmp @hello
@out:
	jsr disp_linefeed

	ldx #$55
	ldy #$00
@xloop:
@yloop:
	stx NUM1+1
	sty NUM1
	jsr out_dec
	jsr disp_linefeed
	iny
	bne @xloop
	inx
	txa
	sta IO_GPIO0
	jmp @xloop
	

.RODATA
message:
	.asciiz "Hello, World!"
	; .asciiz "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqqrstuvwxyz"
