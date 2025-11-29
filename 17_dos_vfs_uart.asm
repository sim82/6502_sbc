.code
.import fgetc, fputc, putc, print_message, print_hex8, print_hex16, fpurge, put_newline
.import update_fletch16
.import dbg_byte
.export vfs_uart_open, vfs_uart_getc, vfs_uart_next_block
.include "17_dos.inc"

; open file on uart channel 1 in block mode (512byte)
vfs_uart_open:
	save_regs
	
	lda #$ff
	sta zp_io_bw_eof
	lda #$00
	sta zp_io_bl_l
	sta zp_io_bl_h
	
	jsr fgetc
	sta oss_receive_size
	; jsr print_hex8
	jsr fgetc	; and high byte
	sta oss_receive_size + 1
	; jsr print_hex8
	; check for file error: file size $ffff
	cmp #$FF
	bne @no_error
	lda oss_receive_size
	cmp #$FF
	bne @no_error
	; fell through both times -> error
	clc
	restore_regs
	rts

@no_error:
	lda #0
	sta zp_fletch_1
	sta zp_fletch_2
	sta zp_io_bw_eof	; clear eof

	jsr load_block_to_iobuf
	restore_regs
	rts


vfs_uart_getc:
	save_xy

	; check IO_BL < oss_receive_size (eof)
	; NOTE: using IO_BL - oss_receive_size. Carry is set if there is no underflow, i.e. IO_BL >= oss_receive_size. Inverted carry is so fucking weird...
	sec
	lda zp_io_bl_l
	sbc oss_receive_size

	lda zp_io_bl_h
	sbc oss_receive_size + 1
	bcs @eof
	; lda zp_io_bl_l
	; cmp oss_receive_size
	; bne @no_eof

	; lda zp_io_bl_h
	; cmp oss_receive_size + 1
	; beq @eof

@no_eof:
	lda zp_io_bl_h
	lsr 
	lda zp_io_bl_l
	ror
	tay
	; y contains the 'word index' (the upper 8bit of the read ptr, i.e. the index into either the high or low io buffer page)
	; the carry flag contains the lowest bit, 0 means read from low op buffer, 1 from high
		
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

	jsr read_next_block_to_iobuf
	bcs @skip_fill_buffer
	; directly set EOF if read failed
	ldy #$FF
	sty zp_io_bw_eof
@skip_fill_buffer:
	pla
	sec
	restore_xy
	rts
@eof:
	lda #%00001111
	sta IO_GPIO0
	lda #'X'
	clc
	restore_xy
	rts

vfs_uart_next_block:
	save_xy
	clc
	; increase read pointer by $200. An overflow always means EOF (for files > $fd00).
	lda #02
	adc zp_io_bl_h
	bcs @eof
	sta zp_io_bl_h

	sec
	lda zp_io_bl_l
	sbc oss_receive_size

	lda zp_io_bl_h
	sbc oss_receive_size + 1
	bcs @eof
	jsr read_next_block_to_iobuf
	; lda zp_io_bl_h
	; sta ARG0
	; jsr dbg_byte
	; lda oss_receive_size
	; sta ARG0
	; jsr dbg_byte
	; jsr put_newline

	; lda oss_receive_size + 1
	; sta ARG0
	; jsr dbg_byte
	restore_xy
	sec
	rts
@eof:
	
	lda #%11110000
	sta IO_GPIO0
	lda #'X'
	clc
	restore_xy
	rts

; outdated: keep for reference
; read 512 byte block. Treat it as 256 x 16bit words and store 
; low/high bytes in separate buffers to simplify indexing
; NOTE: this is an intermediate step to make the 'IO' layer ready for the common 512byte block size
; used by IDE and others.
read_next_block_to_iobuf_interleaved:
	lda #'b'
	jsr fputc
	ldy #$00
@loop_full_block:
	jsr fgetc
	sta IO_BUFFER_L, y
	jsr update_fletch16
	jsr fgetc
	sta IO_BUFFER_H, y
	jsr update_fletch16
	iny
	bne @loop_full_block
	jsr check_extra
	lda #%0000000
	sta IO_GPIO0
	sec
	rts
@end:
	rts

; read 512 byte block from uart, put sequentially into IO_BUFFER_L / IO_BUFFER_H
load_block_to_iobuf:
read_next_block_to_iobuf:
	lda #'b'
	jsr fputc
	ldy #$00
@loop_full_block:
	jsr fgetc
	sta IO_BUFFER_L, y
	jsr update_fletch16
	iny
	bne @loop_full_block
	ldy #$00

@loop_full_block2:
	jsr fgetc
	sta IO_BUFFER_H, y
	jsr update_fletch16
	iny
	bne @loop_full_block2

	jsr check_extra
	lda #%0000000
	sta IO_GPIO0
	sec
	rts


check_extra:
	jsr fpurge
; 	jsr fgetc_nonblocking
; 	bcc @end
; 	lda #'X'
; 	jsr putc
; 	jsr fpurgec

@end:
	rts

msg_read_full_block:
	.byte "read full page", $0A, $0D, $00
