.import dbg_byte
.import vfs_ide_set_lba, vfs_ide_read_block
.export fs_cfs1_find
.include "17_dos.inc"
.code

fs_cfs1_find:
	sta zp_ptr
	stx zp_ptr + 1
	lda #$00
	ldx #$00
	ldy #$00
	jsr vfs_ide_set_lba
	jsr vfs_ide_read_block
	lda #<IO_BUFFER_L
	sta zp_al
	lda #>IO_BUFFER_L
	sta zp_ah
	jsr lookup_name
	rts
    

lookup_name:
	; search for filename pointed to in zp_ptr in filename list pointed to by zp_a
	; step over list in 16 byte steps 
@outer_loop:
	ldy #00
@inner_loop:
	lda (zp_a), y
	sta ARG0
	jsr dbg_byte

	lda (zp_ptr), y
	sta ARG0
	jsr dbg_byte
	lda (zp_ptr), y

	cmp (zp_a), y
	bne @no_match
	iny
	
	sty ARG0
	jsr dbg_byte

	cpy #12
	beq @match
	jmp @inner_loop
@no_match:
	lda #16
	adc zp_ah
	sta zp_ah
	bne @outer_loop
@match:
; found match in entry currently pointed to by (zp_a) -> load lba l/m/h from bytes 12-14 
	ldy #12
	lda (zp_a), y
	pha
	iny
	lda (zp_a), y
	pha
	iny
	lda (zp_a), y 
	pha

	ply
	plx
	pla
	sec
	rts
