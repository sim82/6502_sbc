
.INCLUDE "std.inc"
.import os_alloc, os_putc, os_getc, os_fopen, os_fgetc, os_print_string, os_putnl, os_get_argn, os_get_arg, os_print_dec

IP = $90 ; meh, bootloaded clobbers ZP + $80... TODO: move it down to $00 to preserve more app state after reset
JMP_ADDR = IP + 2
MEM_OPERAND = JMP_ADDR + 2
TMP_A = MEM_OPERAND + 1

.BSS
variables:
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
	.WORD $0000			; $06
	.WORD op_print			; $08
	.WORD $0000			; $0a
	.WORD $0000			; $0c
	.WORD $0000			; $0e
	.WORD op_bne			; $10
	.WORD op_beq			; $12
	.WORD op_bmi			; $14
	.WORD op_bpl			; $16

op_break:
	rts

op_store_immediate:
	iny
	ldx code, y
	iny
	lda code, y
	sta variables, x
	jmp normal_return

op_add_immediate:
	iny
	ldx code, y
	iny
	lda code, y
	clc
	adc variables, x
	sta variables, x
	jmp normal_return

branch_setup:
	iny
	ldx code, y
	lda variables, x
	sta TMP_A ; first operand goes into A for comparison. save on stack

	iny
	ldx code, y
	lda variables, x
	; sta MEM_OPERAND ; second operand goes into MEM for comparison.
	sta MEM_OPERAND
	iny
	lda TMP_A
	cmp MEM_OPERAND
	rts

op_bne:
	jsr branch_setup
	bne op_branch_do_jmp
	jmp normal_return
op_beq:
	jsr branch_setup
	beq op_branch_do_jmp
	jmp normal_return
op_bmi:
	jsr branch_setup
	bmi op_branch_do_jmp
	jmp normal_return
op_bpl:
	jsr branch_setup
	bpl op_branch_do_jmp
	jmp normal_return

op_branch_do_jmp:
	lda code, y
	sta IP
	jmp mod_ip_return


op_print:
	iny
	ldx code, y
	lda variables, x
	ldx #$00
	jsr os_print_dec
	jsr os_putnl
	iny
	tya
	sta IP
	jmp mainloop
	
.RODATA
filename:
	.byte "test1.bs02", $00

