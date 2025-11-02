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

	jsr load_page_to_iobuf
	restore_regs
	rts

load_page_to_iobuf:
	lda #<IO_BUFFER
	sta IO_ADDR
	
	lda #>IO_BUFFER
	sta IO_ADDR + 1
	
	jsr load_page_to_iobuf_gen
	stx IO_BW_END
	ldx #00
	stx IO_BW_PTR
	rts

fgetc_buf:
	save_xy
	ldy IO_BW_EOF
	bne @eof

	ldy IO_BW_PTR
	lda IO_BUFFER, y
	iny
	cpy IO_BW_END
	sty IO_BW_PTR
	bne @skip_fill_buffer 	; if we are not yet a the end of the input buffer, skip re-filling it
	pha
	jsr load_page_to_iobuf
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



; internal function: load next page for open file into (IO_ADDR)
; NOTE: registers are clobbered!
; return:
; - if more data was read (not EOF)
;   - carry is set
;   - (IO_ADDR) contains valid file data
;   - x contains number of valid bytes in (IO_ADDR), 00 == 256 means a full page was read
; - if no more data was read carry is cleared, register / (IO_ADDR) content is undefined
load_page_to_iobuf_gen:
	; print_message_from_ptr msg_read_full_page
	; sei
	ldx RECEIVE_SIZE + 1	; use receive size high byte to determine if a full page shall be read
	beq @non_full_page

	
	lda #'b'		; send 'b' command to signal 'send next page'
	jsr fputc

	ldy #$00		; y: count byte inside page
@loop_full_page:
	jsr fgetc	; recv next byte
	sta (IO_ADDR), y	;  and store to IO_BUFFER + y
	jsr update_fletch16
	iny
	bne @loop_full_page	; end on y wrap around

	dec RECEIVE_SIZE + 1	; dec remaining size 
	ldx #$00                ; end index is FF + 1 (i.e. read buffer until index register wrap around)

	jsr check_extra
	sec
	; cli
	rts

	;
	; reminder, always less than 256 bytes
	;
@non_full_page:
	; print_message_from_ptr msg_read_page
	ldy #00
	; don't send 'b' if last page is empty (i.e. size is a multiple of 256)
	cpy RECEIVE_SIZE
	beq @end_empty
	lda #'b'		; send 'b' command to signal 'send next page'
	jsr fputc
	; lda RECEIVE_SIZE
	; jsr print_hex8
@non_full_page_loop:
	cpy RECEIVE_SIZE	; compare with lower byte of remaining size
	beq @end
	jsr fgetc	; recv next byte
	; lda #%11001100
	; sta IO_GPIO0
	sta (IO_ADDR), y	;  and store to IO_BUFFER + y
	jsr update_fletch16
	iny
	; sty IO_GPIO0
	jmp @non_full_page_loop

@end:
	; inx ; this is a bit iffy? why don't we need the x+1? \
	; meh, it is just a regular 0 based size / index. 256 == 0 in the full page case...
	ldx RECEIVE_SIZE
	ldy #$00
	sty RECEIVE_SIZE
	jsr check_extra
	sec
	; cli
	rts

@end_empty:
	clc
	; cli
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
