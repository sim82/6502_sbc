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
	sta A_TEMP ; A_TEMP contains requested span size

	ldx #$00 ; counter for start of span (OPT: store smallest free page index)

@outer_loop:
	ldy A_TEMP ; restore span size
	stx X_TEMP ; save start of current span (used in success case)
@inner_loop:
	lda PAGETABLE, x
	bmi @non_empty
	
	dey
	beq @empty_span ; x zero -> found empty span

	inx
	beq @out_of_memory
	jmp @inner_loop


@non_empty:
	inx
	beq @out_of_memory ; iny overflow

	jmp @outer_loop

@empty_span:

; mark pages as allocated
	ldy A_TEMP
	ldx X_TEMP 
@mark_loop:
	jsr set_page_allocated
	inx
	dey
	bne @mark_loop

	lda X_TEMP
	sec
	jmp @exit

@out_of_memory:
	clc

@exit:
	restore_xy
	rts
