.code
.import fgetc, fputc, putc, print_message, print_hex8, print_hex16, fpurge
.export read_file_paged, print_fletch16, update_fletch16
.include "17_dos.inc"


; 
; this is deprecated in favor of 512byte block IO
;

; zp_io_addr: 16bit destination address
; IO_FUN: address of per-page io completion function (after a page was loaded into (zp_io_addr)).
;         (IO_FUN) is called with subroutine semantics (i.e. do rts to return), X register contains size of
;         current page ($00 means full page). Code in IO_FUN is allowed to modify zp_io_addr, which enables easy loding in to
;         consecutove pages (use e.g. for binary loading)
read_file_paged:
	save_regs
	jsr fgetc	; read size low byte
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
	;
	; outer loop over all received pages
	; pages are loaded into IO_BUFFER one by one
	;
@load_page_loop:
	jsr load_page_to_iobuf_gen
	bcc @end
	; hack: simulate indirect jsr using indirect jump trampoline (is this a new invention or just what ye olde folks called a vector?)
	jsr @io_fun_trampoline
	jmp @load_page_loop	; continue with next page

@end:
	sec
	restore_regs
	rts

@io_fun_trampoline:
	jmp (IO_FUN)



; internal function: load next page for open file into (zp_io_addr)
; NOTE: registers are clobbered!
; return:
; - if more data was read (not EOF)
;   - carry is set
;   - (zp_io_addr) contains valid file data
;   - x contains number of valid bytes in (zp_io_addr), 00 == 256 means a full page was read
; - if no more data was read carry is cleared, register / (zp_io_addr) content is undefined
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
	sta (zp_io_addr), y	;  and store to IO_BUFFER + y
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
	sta (zp_io_addr), y	;  and store to IO_BUFFER + y
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

	; update fletch16 chksum with value in a
	; will NOT preserve a!
update_fletch16:
	; pha
	clc
	adc zp_fletch_1
	sta zp_fletch_1
	clc
	adc zp_fletch_2
	sta zp_fletch_2
	; pla
	rts

print_fletch16:
	lda zp_fletch_1
	ldx zp_fletch_2
	jsr print_hex16
	rts
	

msg_read_full_page:
	.byte "read full page", $0A, $0D, $00
msg_read_page:
	.byte "read partial page", $0A, $0D, $00
msg_read_eof:
	.byte "end of file", $0A, $0D, $00
