
.import putc, fputc, fpurge, open_file_nonpaged, fgetc_nonpaged, getc, fgetc_block, open_file_c1block
.export vfs_open, vfs_getc
.include "17_dos.inc"
.code

vfs_open:
	sta ZP_PTR
	stx ZP_PTR + 1
	tya
	pha
	jsr fpurge
	lda #'w'
	jsr fputc
	ldy #$00
@send_filename_loop:
	lda (ZP_PTR), y
	jsr fputc
	beq @end_of_filename ; meh, it is a bit of a stretch to expect fputc to preserve zero flag...
	iny
	jmp @send_filename_loop
@end_of_filename:
	jsr open_file_c1block
	; setup fgetc vector
	lda #<fgetc_block
	sta FGETC_L
	lda #>fgetc_block
	sta FGETC_H
	pla
	tya
	rts

vfs_getc:
	; jump through fgetc vector
	jmp (FGETC_L)
