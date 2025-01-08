
.INCLUDE "std.inc"
.import os_alloc, os_putc, os_getc, os_fopen, os_fgetc, os_print_string, os_putnl, os_get_argn, os_get_arg, os_print_dec

IP = $90 ; meh, bootloaded clobbers ZP + $80... TODO: move it down to $00 to preserve more app state after reset
JMP_ADDR = IP + 2
MEM_OPERAND = JMP_ADDR + 2
TMP_A = MEM_OPERAND + 1
OP1L = TMP_A + 1
OP1H = OP1L + 1
OP2L = OP1H + 1
OP2H = OP2L + 1

.BSS
variables:
	.RES $100
variables_high:
	.RES $100

code:
	.RES $100
.CODE
	; rts
	lda #<filename
	ldx #>filename
	jsr os_fopen
	bcc exit
	ldx #$00
@file_loop:
	jsr os_fgetc
	bcc @eof
	sta code, x
	inx
	jmp @file_loop
@eof:

	lda #$00
	sta IP

; 'slow-path' return: reload IP
mod_ip_return:
	ldy IP
	jmp mainloop

; 'common-path' return: y-reg contains IP-1 from last operation
; this should be the normal way for non-branching operations to return
normal_return:
	iny
	sty IP
mainloop:
	ldx code, y
	lda opcode_table, x
	sta JMP_ADDR
	
	lda opcode_table + 1, x
	sta JMP_ADDR + 1

	; NOTE: make sure to preserve current opcode in X! branch op depends on that for optimization
	jmp (JMP_ADDR)

exit:
	rts
opcode_table:
	.WORD op_break			; $00
	.WORD op_store_immediate	; $02
	.WORD op_add_immediate		; $04
	.WORD op_store_immediate16	; $06
	.WORD op_print			; $08
	.WORD $0000			; $0a
	.WORD $0000			; $0c
	.WORD $0000			; $0e
	.WORD op_bne16			; $10
	.WORD 0000			; $12
	.WORD op_blt16			; $14
	.WORD op_bge16			; $16

op_break:
	rts

op_bne16:
	jsr branch_setup2
	lda OP1H
	cmp OP2H
	bne take_branch
	lda OP1L
	cmp OP2L
	bne take_branch
	jmp normal_return

op_blt16:
	jsr branch_setup2
	lda OP1H
	cmp OP2H
	bcc take_branch
	bne normal_return
	lda OP1L
	cmp OP2L
	bcc take_branch
	jmp normal_return

op_bge16:
	jsr branch_setup2
	lda OP1H
	cmp OP2H
	bcc normal_return
	bne take_branch
	lda OP1L
	cmp OP2L
	bcs take_branch
	jmp normal_return

take_branch:
	lda code, y
	sta IP
	jmp mod_ip_return

op_store_immediate:
	iny
	ldx code, y
	iny
	lda code, y
	sta variables, x
	lda #$00
	sta variables_high, x
	jmp normal_return

op_store_immediate16:
	iny
	ldx code, y
	iny
	lda code, y
	sta variables, x
	iny
	lda code, y
	sta variables_high, x
	jmp normal_return

	
op_add_immediate:
	iny
	ldx code, y
	iny
	lda code, y
	clc
	adc variables, x
	sta variables, x
	lda variables_high, x
	adc #$00
	sta variables_high, x
	jmp normal_return

branch_setup2:
	iny
	ldx code, y
	lda variables, x
	sta OP1L
	lda variables_high, x
	sta OP1H

	iny
	ldx code, y
	lda variables, x
	sta OP2L
	lda variables_high, x
	sta OP2H
	iny
	rts
	



op_print:
; rts
	iny
	ldx code, y
	lda variables, x
	sta TMP_A
	lda variables_high, x
	tax
	lda TMP_A
	jsr os_print_dec
	jsr os_putnl
	iny
	tya
	sta IP
	jmp mainloop
	
.RODATA
filename:
	.byte "test1.bs02", $00

