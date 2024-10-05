.code
.import fgetc, fputc, putc
.export read_file_paged, open_file_nonpaged, fgetc_buf
.include "17_dos.inc"

open_file_nonpaged:
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
	rts

@no_error:

load_page_to_iobuf:
	ldy #$00		; y: count byte inside page
	ldx RECEIVE_SIZE + 1	; use receive size high byte to determine if a full page shall be read
	beq @non_full_page

	lda #'b'		; send 'b' command to signal 'send next page'
	jsr fputc

@loop_full_page:
	jsr fgetc	; recv next byte
	sta (IO_ADDR), y	;  and store to (IO_ADDR) + y
	jsr update_fletch16
	iny
	bne @loop_full_page	; end on y wrap around

	dec RECEIVE_SIZE + 1	; dec remaining size 
	ldx #$00                ; end index is FF + 1 (i.e. read buffer until index register wrap around)
	stx IO_BW_PTR
	stx IO_BW_END
	sec
	rts

	;
	; reminder, always less than 256 bytes
	;
@non_full_page:
	; don't send 'b' if last page is empty (i.e. size is a multiple of 256)
	cpy RECEIVE_SIZE
	beq @end
	lda #'b'		; send 'b' command to signal 'send next page'
	jsr fputc
@non_full_page_loop:
	cpy RECEIVE_SIZE	; compare with lower byte of remaining size
	beq @end
	jsr fgetc	; recv next byte
	sta (IO_ADDR), y	;  and store to TARGET_ADDR + y
	jsr update_fletch16
	iny
	jmp @non_full_page_loop

@end:
	ldx RECEIVE_SIZE
	stx IO_BW_END
	ldx #$00
	stx IO_BW_PTR
	rts


fgetc_buf:
	ldy IO_BW_PTR
	lda (IO_ADDR), y
	iny
	cpy IO_BW_END
	sty IO_BW_PTR
	beq @fill_buffer
	sec
	rts
@fill_buffer:
	
	jsr load_page_to_iobuf
	rts

; IO_ADDR: 16bit destination address
; IO_FUN: address of per-page io completion function (after a page was loaded into (IO_ADDR)).
;         (IO_FUN) is called with subroutine semantics (i.e. do rts to return), X register contains size of
;         current page ($00 means full page). Code in IO_FUN is allowed to modify IO_ADDR, which enables easy loding in to
;         consecutove pages (use e.g. for binary loading)
read_file_paged:
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
	rts

@no_error:
	;
	; outer loop over all received pages
	; pages are loaded into IO_BUFFER one by one
	;
@load_page_loop:
	; request next page
	; lda #'b'		; send 'b' command to signal 'send next page'
	; jsr fputc

	ldy #$00		; y: count byte inside page
	ldx RECEIVE_SIZE + 1	; use receive size high byte to determine if a full page shall be read
	beq @non_full_page

	lda #'b'		; send 'b' command to signal 'send next page'
	jsr fputc
	;
	; full page case: exactly 256 bytes
	;
@loop_full_page:
	jsr fgetc	; recv next byte
	sta (IO_ADDR), y	;  and store to (IO_ADDR) + y
	jsr update_fletch16
	iny
	bne @loop_full_page	; end on y wrap around

	dec RECEIVE_SIZE + 1	; dec remaining size 
	ldx #$00                ; end index is FF + 1 (i.e. read buffer until index register wrap around)
	; hack: simulate indirect jsr using indirect jump trampoline (is this a new invention or just what ye olde folks called a vector?)
	jsr @io_fun_trampoline
	jmp @load_page_loop	; continue with next page

	
	;
	; reminder, always less than 256 bytes
	;
@non_full_page:
	; don't send 'b' if last page is empty (i.e. size is a multiple of 256)
	cpy RECEIVE_SIZE
	beq @end
	lda #'b'		; send 'b' command to signal 'send next page'
	jsr fputc
@non_full_page_loop:
	cpy RECEIVE_SIZE	; compare with lower byte of remaining size
	beq @end
	jsr fgetc	; recv next byte
	sta (IO_ADDR), y	;  and store to TARGET_ADDR + y
	jsr update_fletch16
	iny
	jmp @non_full_page_loop

@end:
	ldx RECEIVE_SIZE
	; hack: simulate indirect jsr using indirect jump trampoline
	jsr @io_fun_trampoline
		
	sec
	rts

@io_fun_trampoline:
	jmp (IO_FUN)




	; update fletch16 chksum with value in a
	; will NOT preserve a!
update_fletch16:
	; pha
	clc
	adc FLETCH_1
	sta FLETCH_1
	clc
	adc FLETCH_2
	sta FLETCH_2
	; pla
	rts

