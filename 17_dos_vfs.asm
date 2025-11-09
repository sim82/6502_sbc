
.import putc, fputc, fpurge, open_file_nonpaged, fgetc_nonpaged, getc
.import vfs_uart_open, vfs_uart_getc, vfs_uart_next_block ; uart driver
.import vfs_ide_open, vfs_ide_getc
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
        cmp #'#'
        beq @open_disk

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
	jsr vfs_ide_open

	lda #<vfs_ide_getc
	sta zp_fgetc_l
	lda #>vfs_ide_getc
	sta zp_fgetc_h

        ply
        rts

vfs_getc:
	; jump through fgetc vector
	jmp (zp_fgetc_l)

vfs_next_block:
	; hack
	jmp vfs_uart_next_block

