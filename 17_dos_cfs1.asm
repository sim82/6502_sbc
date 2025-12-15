.import dbg_byte
.import vfs_ide_set_lba, vfs_ide_read_block
.import putc, put_newline
.export fs_cfs1_find, fs_cfs1_next_link, fs_cfs1_set_link, fs_cfs1_open, fs_cfs1_getc
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

fs_cfs1_open:
	sta oss_receive_size
	stx oss_receive_size + 1

	lda #$ff
	sta zp_io_bw_eof
	lda #$00
	sta zp_io_bl_l
	sta zp_io_bl_h
	sta zp_io_bw_eof
	lda oss_cfs1_linkl
	sta oss_ide_lba_low
	lda oss_cfs1_linkh
	clc
	adc #$01 ; add 256 blocks of link list
	sta oss_ide_lba_mid
	lda #$00
	sta oss_ide_lba_high
	
	jsr vfs_ide_read_block
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
	
	; clear carry if a == x == 0 (end of list)
	sec
	cmp #$00
	bne @not_end
	cpx #$00
	bne @not_end

	; sta ARG0
	; jsr dbg_byte
	; stx ARG0
	; jsr dbg_byte
	; jsr put_newline
	clc
@not_end:
	restore_regs
	rts


; =============================
; this is all a bit crap since it duplicates most of the actual reading from vfs_ide_getc.
; It could be made more generic, but I don't really feel like overengineering it just yet... mostly a POC
fs_cfs1_getc:
	save_xy
	lda zp_io_bw_eof
	bne @eof

	lda zp_io_bl_l
	cmp oss_receive_size
	bne @no_eof

	lda zp_io_bl_h
	cmp oss_receive_size + 1
	beq @eof

@no_eof:
	; low byte of io ptr -> y (index inside page)
	ldy zp_io_bl_l
	; high byte of io ptr -> lowest bit determines low / high page of current 512 byte buffer
	lda zp_io_bl_h
	ror
		
	bcs @high_byte
	lda IO_BUFFER_L, y
	bcc @end_read ; opt: known carry state, rel. jump
@high_byte:
	lda IO_BUFFER_H, y
@end_read:

	pha ; save current byte (could use x reg...)

	; inc read pointer
	lda #$1
	clc
	adc zp_io_bl_l
	sta zp_io_bl_l
	lda #$0
	adc zp_io_bl_h
	sta zp_io_bl_h
	
	; check if end of buffer:
	; if all 9 lowest bits are 0 after pointer inc this means we stepped into a new 512byte block
	; -> needs refill
	lda zp_io_bl_h
	and #$01
	bne @skip_fill_buffer

	lda zp_io_bl_l
	bne @skip_fill_buffer

	; read next block location from link table
	jsr fs_cfs1_next_link
	bcc @eof_link

	; calculate LBA addresses and read next block
	lda oss_cfs1_linkl
	sta oss_ide_lba_low
	lda oss_cfs1_linkh
	clc
	adc #$01 ; add 256 blocks of link list
	sta oss_ide_lba_mid
	lda #$00
	sta oss_ide_lba_high
	
	jsr vfs_ide_read_block
	bcc @eof_link

@skip_fill_buffer:
	; exit getc normally: pull temp A from stack and set carry
	pla
	sec
	restore_xy
	rts

@eof_link:
	; jump here if eof or any error is encountered while reading the next link / block
	; NOTE: expecting that temp A value is on the stack!
	pla ; repair stack (still contains temp A value)
	ldy #$FF
	sty zp_io_bw_eof

@eof:
	lda #%01010101
	sta IO_GPIO0
	lda #'X'
	clc
	restore_xy
	rts
