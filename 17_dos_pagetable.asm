.code
.import fgetc, fputc, putc, print_message, print_hex8
.export init_pagetable, alloc_page, alloc_page_span
.include "17_dos.inc"

PF_ALLOCATED = %10000000 ; OPT: use highest bit to enable bmi in scan loop
PF_SPAN_START = %00000001
PF_SPAN_END = %00000010
PF_STATIC = %00000100

.macro set_pagex_flag flag
	lda #flag
	sta PAGETABLE, x
.endmacro

.macro set_page_flag offs, flag
	ldx #offs
	set_pagex_flag flag
.endmacro

.macro alloc_static offs
	set_page_flag offs, PF_ALLOCATED | PF_STATIC
.endmacro

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; init_pagetable

init_pagetable:
	save_regs
	ldx #$00
@clear_loop:
	set_pagex_flag $00
	inx
	bne @clear_loop
	
	; mark pages $00 - $04 and $f0 - $ff as static / allocated
	; (technically it is $04 'down to' $f0, via x underflow)
	ldx #$04
@lower_reserved_loop:
	set_pagex_flag PF_ALLOCATED | PF_STATIC
	dex
	cpx #$ef
	bne @lower_reserved_loop
	
	jsr clobber_free_pages
	restore_regs
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; alloc_page:
; single page allocator

alloc_page:
	save_xy
	ldx #$00

@loop:
	lda PAGETABLE, x
	bpl @empty_page ; OPT: check highest bit
	inx
	beq @out_of_memory ; inx overflow -> reached end of pagetable
	jmp @loop

@empty_page:
	set_pagex_flag PF_ALLOCATED | PF_SPAN_START | PF_SPAN_END
	txa
	sec
	jmp @exit
	

@out_of_memory:
	clc
@exit:
	restore_xy
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; alloc_page_span:
; page allocator for spans of 1..n pages

alloc_page_span:
	; fast path: jmp directly into single page allocator. This also simplifies the code below
	cmp #$01
	bne @multi_page
	jmp alloc_page
@multi_page:
	save_xy
	cmp #$00
	beq @out_of_memory
	
	sta A_TEMP ; A_TEMP contains requested span size

	ldx #$00 ; counter for start of span (OPT: store smallest free page index)

@outer_loop:
	ldy A_TEMP ; restore span size
	stx X_TEMP ; save start of current span (used in success case)
@inner_loop:
	lda PAGETABLE, x
	bmi @non_empty ; OPT: check highest bit
	
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
	dey ; stop before last page. 
	ldx X_TEMP 
@mark_loop:
	set_pagex_flag PF_ALLOCATED
	inx
	dey
	bne @mark_loop
	set_pagex_flag PF_ALLOCATED | PF_SPAN_END ; also set 'span end' bit on last page
	ldx X_TEMP

	; a bit crappy, but keeps the loop simple: go back to first page and also set PF_SPAN_START
	set_pagex_flag PF_ALLOCATED | PF_SPAN_START
	txa 
	sec
	jmp @exit

@out_of_memory:
	clc

@exit:
	restore_xy
	rts


clobber_free_pages:
	ldx #$00
	stx AL
@loop:
	lda PAGETABLE, x
	bmi @skip

	sta IO_GPIO0
	stx AH
	ldy #$00
@inner_loop:
	; pure gimmick...
	lda #$de
	sta (AL), y
	iny
	lda #$ad
	sta (AL), y
	iny
	lda #$be
	sta (AL), y
	iny
	lda #$ef
	sta (AL), y
	iny
	bne @inner_loop
	
@skip:
	inx
	bne @loop

	rts
