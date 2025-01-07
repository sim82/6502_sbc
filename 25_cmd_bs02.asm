
.INCLUDE "std.inc"
.import os_alloc, os_putc, os_getc, os_fopen, os_fgetc, os_print_string, os_putnl, os_get_argn, os_get_arg, os_print_dec

IP = $90 ; meh, bootloaded clobbers ZP + $80... TODO: move it down to $00 to preserve more app state after reset
JMP_ADDR = IP + 2
TMP1 = JMP_ADDR + 2
TMP2 = TMP1 + 1

.BSS
variables:
	.RES $100

code:
	.RES $100
.CODE
	lda #$ff
	sta TMP2
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
	.WORD op_branch			; $10
	.WORD op_branch			; $12
	.WORD op_branch			; $14
	.WORD op_branch			; $16

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

op_branch:
	stx TMP2 ; store opcode
	iny
	ldx code, y
	lda variables, x
	pha ; first operand goes into A for comparison. save on stack

	iny
	ldx code, y
	lda variables, x
	sta TMP1 ; second operand goes into MEM for comparison.
	iny
	; jump to comparison op 
	; TODO: check if this is really a good idea, or if it is better to put the common code in function call
	lda TMP2
	and #$0f
	tax
	lda cmp_table, x
	sta JMP_ADDR
	lda cmp_table + 1, x
	sta JMP_ADDR + 1
	pla
	cmp TMP1
	jmp (JMP_ADDR)

op_branch_do_jmp:
	lda code, y
	sta IP
	jmp mod_ip_return

cmp_ne:
	bne op_branch_do_jmp
	jmp normal_return
cmp_eq:
	beq op_branch_do_jmp
	jmp normal_return
cmp_mi:
	bmi op_branch_do_jmp
	jmp normal_return
cmp_pl:
	bpl op_branch_do_jmp
	jmp normal_return
cmp_table:
	.WORD cmp_ne
	.WORD cmp_eq
	.WORD cmp_mi
	.WORD cmp_pl



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

