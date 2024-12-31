.code
.import fgetc, fputc, putc, print_message, print_hex8
.export init_pagetable, alloc_page, alloc_page_span
.include "17_dos.inc"
.include "std.inc"


.macro alloc_static offs
	ldx #offs
	jsr set_page_allocated
.endmacro

init_pagetable:
	save_regs
	ldx #$00
@clear_loop:
	jsr set_page_free
	inx
	bne @clear_loop
	
	alloc_static $00 ; zero page
	alloc_static $01 ; stack
	alloc_static >PAGETABLE
	alloc_static >INPUT_LINE
	alloc_static >IO_BUFFER
	alloc_static $fe
	alloc_static $ff
	restore_regs
	rts


set_page_allocated:
	lda #%10000000
	sta PAGETABLE, x
	rts

set_page_free:
	lda #%00000000
	sta PAGETABLE, x
	rts

alloc_page:
	save_xy
	ldx #$00

@loop:
	lda PAGETABLE, x
	bpl @empty_page
	inx
	beq @out_of_memory ; inx overflow -> reached end of pagetable
	jmp @loop

@empty_page:
	jsr set_page_allocated
	txa
	sec
	jmp @exit
	

@out_of_memory:
	clc
@exit:
	restore_xy
	rts

alloc_page_span:
	
	save_xy
	stx A_TEMP

	ldy #$00

@outer_loop:
	ldx A_TEMP ; restore size
	sty Y_TEMP ; save start of span
@inner_loop:
	lda PAGETABLE, y

	bmi @non_empty
	
	dex
	beq @empty_span ; x zero -> found empty span

	iny
	beq @out_of_memory
	jmp @inner_loop


@non_empty:
	iny
	beq @out_of_memory ; iny overflow

	jmp @outer_loop

@empty_span:

; mark pages as allocated
	ldx Y_TEMP
	ldy A_TEMP
@mark_loop:
	jsr set_page_allocated
	inx
	dey
	bne @mark_loop

	
	lda Y_TEMP
	sec
	jmp @exit

@out_of_memory:
	clc

@exit:
	restore_xy
	rts
