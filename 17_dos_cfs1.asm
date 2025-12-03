.import dbg_byte
.import vfs_ide_set_lba, vfs_ide_read_block
.import putc
.export fs_cfs1_find, fs_cfs1_next_link, fs_cfs1_set_link
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
	lda (zp_ptr), y
	cmp (zp_a), y
	bne @no_match
	cmp #00
	beq @match ; hit termination in both strings -> match
	iny
	
	; sty ARG0
	; jsr dbg_byte

	cpy #12
	beq @match ; hit end of string -> match
	jmp @inner_loop
@no_match:
	clc
	lda #16
	adc zp_al
	sta zp_al
	bne @outer_loop 
	; outer_loop terminated because of wrap around -> not found
	clc
	rts
@match:
; found match in entry currently pointed to by (zp_a) -> load lba l/m/h from bytes 12-14 
	ldy #11
	lda (zp_a), y
	pha
	iny
	lda (zp_a), y
	pha
	; lba h > fake 0
	lda #00
	pha
	
	iny
	lda (zp_a), y 
	sta oss_receive_sizel
	
	iny
	lda (zp_a), y 
	sta oss_receive_sizeh

	ply
	plx
	pla
	sec
	rts

fs_cfs1_set_link:
	sta oss_cfs1_linkl
	stx oss_cfs1_linkh
	rts

fs_cfs1_next_link:
	save_regs
	; link number stored in linkl:linkh
	; there are 256 links per block -> linkh == index of link-table block == lba low (becaus link table starts at 0 0 0)
	; linkl is the offset of the entry inside the link-table block
	lda oss_cfs1_linkh
	ldx #$00
	ldy #$00
	jsr vfs_ide_set_lba
	jsr vfs_ide_read_block

	ldy oss_cfs1_linkl
	ldx IO_BUFFER_H, y ; high / low are stored separately
	lda IO_BUFFER_L, y
	stx oss_cfs1_linkh
	sta oss_cfs1_linkl
	
	restore_regs
	rts
