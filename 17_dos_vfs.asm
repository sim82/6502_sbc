
.import putc, fputc, fpurge, open_file_nonpaged, fgetc_nonpaged, getc, get_arg_hex, dbg_byte
.import vfs_uart_open, vfs_uart_getc, vfs_uart_next_block ; uart driver
.import vfs_ide_open, vfs_ide_getc, vfs_ide_set_lba, vfs_ide_read_block
.import fs_cfs1_find
.export vfs_open, vfs_getc, vfs_next_block
.include "17_dos.inc"
.code

vfs_open:
	sta zp_ptr
	stx zp_ptr + 1
	; tya
	; pha
        phy
        ldy #$00
        lda (zp_ptr), y
	; # prefix: 'raw block number'
        cmp #'#'
        beq @open_disk
	; / prefix: filesystem
	cmp #'/'
	beq @open_cfs1

	; no prefix: load from uart
	jsr fpurge
	lda #'w'
	jsr fputc
	ldy #$00
@send_filename_loop:
	lda (zp_ptr), y
	jsr fputc
	beq @end_of_filename ; meh, it is a bit of a stretch to expect fputc to preserve zero flag...
	iny
	jmp @send_filename_loop
@end_of_filename:
	jsr vfs_uart_open
	; setup fgetc vector
	lda #<vfs_uart_getc
	sta zp_fgetc_l
	lda #>vfs_uart_getc
	sta zp_fgetc_h
	; pla
	; tya
        ply
	rts


@open_disk:
	iny
	jsr get_arg_hex
	
	sta ARG0
	jsr dbg_byte
	ldx #$00
	ldy #$00
	jsr vfs_ide_set_lba

	jsr vfs_ide_open

	lda #<vfs_ide_getc
	sta zp_fgetc_l
	lda #>vfs_ide_getc
	sta zp_fgetc_h

        ply
        rts

@open_cfs1:
	lda zp_ptr
	inc
	ldx zp_ptr + 1
	jsr fs_cfs1_find
	bcs @found
	; file not found
	ply
	rts
@found:
	; lba in a/x/y on return
	jsr vfs_ide_set_lba
	
	; os_receive_size setup by cfs1_find
	lda #<vfs_ide_getc
	sta zp_fgetc_l
	lda #>vfs_ide_getc
	sta zp_fgetc_h

	; redundant: init code from raw vfs_ide open
	lda #0
	sta zp_fletch_1
	sta zp_fletch_2
	sta zp_io_bw_eof	; clear eof
	sta zp_io_bl_l
	sta zp_io_bl_h

	jsr vfs_ide_read_block
	ply
	sec
	rts

vfs_getc:
	; jump through fgetc vector
	jmp (zp_fgetc_l)

vfs_next_block:
	; hack
	jmp vfs_uart_next_block

