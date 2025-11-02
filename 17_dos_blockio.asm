.code
.import fgetc, fputc, putc, print_message, print_hex8, print_hex16, fpurge
.import update_fletch16
.export open_file_c1block
.include "17_dos.inc"

; open file on uart channel 1 in block mode (512byte)
open_file_c1block:
	save_regs
	lda #$ff
	sta IO_BW_EOF
	
	jsr fgetc
	sta RECEIVE_SIZE
	; jsr print_hex8
	jsr fgetc	; and high byte
	sta RECEIVE_SIZE + 1
	; jsr print_hex8
	; check for file error: file size $ffff
	cmp #$FF
	bne @no_error
	lda RECEIVE_SIZE
	cmp #$FF
	bne @no_error
	; fell through both times -> error
	clc
	restore_regs
	rts

@no_error:
	lda #0
	sta FLETCH_1
	sta FLETCH_2
	sta IO_BW_EOF	; clear eof

	jsr load_block_to_iobuf
	restore_regs
	rts

load_block_to_iobuf:
	jsr read_next_block_to_iobuf
	stx IO_BW_END
	ldx #00
	stx IO_BW_PTR
	rts

fgetc_block:
	save_xy
	lda IO_BL_L
	cmp RECEIVE_SIZE
	bne @no_eof
	lda IO_BL_H
	cmp RECEIVE_SIZR + 1
	beq @eof

	; check if end of buffer
	; todo
	lda IO_BL_H
	and #$01
	cmp #$01
	bne @not_empty

	lda IO_BL_L
	cmp #$ff
	bne @not_empty

@not_empty:
	; get index into current buf
	lda IO_BL_H
	lsr 
	lda IO_BL_L
	ror
	tay
	
	
	
	ldy IO_BW_PTR
	lda IO_BUFFER, y
	iny
	cpy IO_BW_END
	sty IO_BW_PTR
	bne @skip_fill_buffer 	; if we are not yet a the end of the input buffer, skip re-filling it
	pha
	jsr load_block_to_iobuf
	pla
	bcs @skip_fill_buffer
	ldy #$FF
	sty IO_BW_EOF
@skip_fill_buffer:

	sec
	restore_xy
	rts
@eof:
	lda #'X'
	clc
	restore_xy
	rts


; read 512 byte block. Treat it as 256 x 16bit words and store 
; low/high bytes in separate buffers to simplify indexing
; NOTE: this is an intermediate step to make the 'IO' layer ready for the common 512byte block size
; used by IDE and others.
read_next_block_to_iobuf:
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
	inx
	bne @loop_full_block
	jsr check_extra
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
