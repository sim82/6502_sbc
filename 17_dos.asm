
.IMPORT put_newline, uart_init, putc, getc, fputc, fgetc, fgetc_nonblocking, fpurge, print_hex16, print_hex8
.import fgetc_buf, open_file_nonpaged
.import reset_tokenize, read_token, retire_token
.import read_file_paged
.import print_message
.import stream_bin
.INCLUDE "std.inc"
.INCLUDE "17_dos.inc"



.CODE
	; init local vars
	lda #$00
	sta INPUT_LINE_PTR

	
	jsr uart_init

; @loop:

; 	jsr getc
; 	bcc @loop
; 	jsr putc
; 	jmp @loop

	
	jsr put_newline
	print_message_from_ptr welcome_message

	lda #'>'
	jsr putc
mainloop:
	jsr read_input
	jmp mainloop

read_input:
	jsr getc
	bcc read_input 		; busy wait for character
	; pha
	; jsr print_hex8
	; jsr put_newline
	; pla
	cmp #$0a 		; ignore LF / \n
	beq read_input
	cmp #$0d 		; enter key is CR / \r 
	bne @no_enter_key
	jsr put_newline		; handle enter: - put newline
	jsr exec_input_line     ;               - execute input line
	lda #'>'
	jsr putc
	rts
@no_enter_key:
	cmp #$08		; handle backspace
	bne @normal_char
	ldy INPUT_LINE_PTR	; check if input line is empty -> ignore backspace
	beq mainloop
	dec INPUT_LINE_PTR	; delete last char (dec ptr)

	; rub-out character on terminal
	jsr putc		; send the backspace (move cursor back)
	lda #' '		; overwrite with space
	jsr putc
	lda #$08		; send another backspace to move cursor back onto space
	jsr putc
	jmp mainloop
@normal_char:
	; TODO: ignore non-printable chars
	ldy INPUT_LINE_PTR	; append normal char to input line
	cpy #INPUT_LINE_LEN	;   check if input line is full
	beq @buf_full
	sta INPUT_LINE, y	;   store char at current input line ptr
	jsr putc		;   local echo
	inc INPUT_LINE_PTR	;   in-place increase input line ptr
	; fall through
@buf_full:
	rts

compare_token:
	ldy #$00
@loop:
	cpy NEXT_TOKEN_END
	beq @found

	lda INPUT_LINE, y ; looks sus... shouldn't this be offset to current token? Works only for the first token (!?)
	; jsr putc
	cmp (ZP_PTR), y
	bne @mismatch
	iny
	jmp @loop

@found:
	; now check if we reached the end of the target string (null termination)
	; iny
	; lda (ZP_PTR), y
	; jsr putc

	lda #$00
	cmp (ZP_PTR), y
	bne @mismatch
	sec
	rts
	
@mismatch:
	clc
	rts
	
cmd_help_str:
	.byte "help", $00
cmd_help:
	print_message_from_ptr welcome_message
	print_message_from_ptr help_message
	rts

cmd_ls_str:
	.byte "ls", $00
cmd_ls:
	print_message_from_ptr help_message
	rts


cmd_cat_str:
	.byte "cat", $00
cmd_cat:
	print_message_from_ptr @purrrr
	jsr retire_token
	jsr read_token
	jsr fpurge
	lda #'r'
	jsr fputc
	ldy NEXT_TOKEN_PTR
@send_filename_loop:
	cpy NEXT_TOKEN_END
	beq @end_of_filename
	lda INPUT_LINE, y
	jsr fputc
	iny
	jmp @send_filename_loop
@end_of_filename:
	lda #$00
	jsr fputc
	store_address IO_BUFFER, IO_ADDR
	store_address cat_iobuffer, IO_FUN
	jsr read_file_paged
	rts
@purrrr:
	.byte "purrrr", $0A, $0D, $00

cmd_rat_str:
	.byte "rat", $00
cmd_rat:
	print_message_from_ptr @purrrr
	jsr retire_token
	jsr read_token
	jsr fpurge
	lda #'r'
	jsr fputc
	ldy NEXT_TOKEN_PTR
@send_filename_loop:
	cpy NEXT_TOKEN_END
	beq @end_of_filename
	lda INPUT_LINE, y
	jsr fputc
	iny
	jmp @send_filename_loop
@end_of_filename:
	lda #$00
	jsr fputc
	jsr open_file_nonpaged
	bcc @end
@byte_loop:
	jsr fgetc_buf
	bcc @end

	; jmp @byte_loop
	cmp #$0A
	bne @jump_linefeed
	lda #$0d
	jsr putc
	lda #$0a

@jump_linefeed:
	jsr putc
	jmp @byte_loop
@end:
	lda FLETCH_1
	ldx FLETCH_2
	jsr print_hex16
	jsr put_newline
	rts
@purrrr:
	.byte "squeeeek", $0A, $0D, $00

cmd_bench_str:
	.byte "bench", $00
cmd_bench:
	jsr retire_token
	jsr read_token
	jsr fpurge
	lda #'r'
	jsr fputc
	ldy NEXT_TOKEN_PTR
@send_filename_loop:
	cpy NEXT_TOKEN_END
	beq @end_of_filename
	lda INPUT_LINE, y
	jsr fputc
	iny
	jmp @send_filename_loop
@end_of_filename:
	lda #$00
	jsr fputc
	store_address IO_BUFFER, IO_ADDR
	store_address @noop, IO_FUN
	lda #$00
	sta ZP_PTR
	jsr read_file_paged
	rts

@noop:
	inc ZP_PTR
	lda ZP_PTR
	jsr print_windmill
	rts

cmd_echo_str:
	.byte "echo", $00
cmd_echo:
	jsr getc
	bcc cmd_echo
	jsr putc
	; endless loop
	jmp cmd_echo

; r - streamed binary load / relocate
cmd_r_str:
	.byte "r", $00
cmd_r:
	print_message_from_ptr @purrrr
	jsr retire_token
	jsr read_token
	jsr fpurge
	lda #'r'
	jsr fputc
	ldy NEXT_TOKEN_PTR
@send_filename_loop:
	cpy NEXT_TOKEN_END
	beq @end_of_filename
	lda INPUT_LINE, y
	jsr fputc
	iny
	jmp @send_filename_loop
@end_of_filename:
	lda #$00
	jsr fputc
	jsr open_file_nonpaged
	bcc @end
	jsr stream_bin
@end:
	lda FLETCH_1
	ldx FLETCH_2
	jsr print_hex16
	jsr put_newline
	bcs @no_error
	
	print_message_from_ptr @error_msg
@no_error:
	rts
@purrrr:
	.byte "stream...", $0A, $0D, $00

@error_msg:
	.byte "error.", $0A, $0D, $00

; m - monitor
cmd_m_str:
	.byte "m", $00
cmd_m:
	lda #$00
	sta ZP_PTR
	lda #$d0
	sta ZP_PTR + 1
	
	ldy #0
@loop:
	cpy #16
	beq @end
	
	lda (ZP_PTR), y
	jsr print_hex8
	lda #' '
	jsr putc
	iny
	jmp @loop
@end:
	rts

; j - jmp
cmd_j_str:
	.byte "j", $00
cmd_j:

	lda #$d0
	sta RECEIVE_POS + 1
	lda #$00
	sta RECEIVE_POS
	jmp (RECEIVE_POS)
	rts
	

exec_input_line:
	jsr fgetc_nonblocking
	bcs exec_input_line
	jsr fpurge
	jsr reset_tokenize
	jsr read_token
	bcs @dispatch_builtin
	jmp @cleanup

@dispatch_builtin:
	dispatch_command cmd_help_str, cmd_help
	dispatch_command cmd_ls_str, cmd_ls
	dispatch_command cmd_cat_str, cmd_cat
	dispatch_command cmd_rat_str, cmd_rat
	dispatch_command cmd_bench_str, cmd_bench
	dispatch_command cmd_echo_str, cmd_echo
	dispatch_command cmd_r_str, cmd_r
	dispatch_command cmd_m_str, cmd_m
	dispatch_command cmd_j_str, cmd_j
	; fall through. successfull commands jump to @cleanup from macro
; @end:
; purge any channel2 input buffer before starting IO
	jsr fpurge
	lda #'o'
	jsr fputc
	ldy #$0
@send_filename_loop:
	cpy NEXT_TOKEN_END
	beq @end_of_filename
	lda INPUT_LINE, y
	jsr fputc
	iny
	jmp @send_filename_loop
@end_of_filename:
	lda #$00
	jsr fputc
	jsr load_binary
	bcc @file_error
	lda RECEIVE_POS
	ldx RECEIVE_POS + 1
	jsr print_hex16
	jsr put_newline
	ldy 0
@delay:
	iny
	bne @delay
	jmp (RECEIVE_POS)

@file_error:
	print_message_from_ptr file_not_found_message
@cleanup:

	ldy #$0
	sty INPUT_LINE_PTR
	jsr put_newline
	rts


load_binary:
	; meaning of IO_ADDR vs RECEIVE_POS: 
	;  - IO_ADDR: in ZP, used for indirect addressing and modified during read
	;  - RECEIVE_POS: no need to be in ZP, used as entry point to program after read

	lda #0
	sta FLETCH_1
	sta FLETCH_2
	jsr fgetc	; read target address low byte
	sta RECEIVE_POS
	sta IO_ADDR
	jsr fgetc	; and high byte
	sta RECEIVE_POS + 1	
	sta IO_ADDR + 1
	; check for file error: target addr $ffff
	cmp #$FF
	bne @no_error
	lda TARGET_ADDR
	cmp #$FF
	bne @no_error
	; fell through both times -> error
	clc
	rts

@no_error:
	; set up for read_file_paged
	store_address @load_binary_page_completion, IO_FUN
	jsr read_file_paged
	bcc @read_error
	lda FLETCH_1
	ldx FLETCH_2
	jsr print_hex16
	jsr put_newline
	sec
@read_error:
	rts

@load_binary_page_completion:
	lda IO_ADDR + 1	; QoL: spin windmill
	jsr print_windmill
	inc IO_ADDR + 1	;  and inc io address by 256 each
	rts
	
	
cat_iobuffer:
	stx ZP_PTR
	ldy #$00
@loop:
	lda IO_BUFFER, y
	jsr putc
	cmp #$0A
	bne @jump_linefeed
	lda #$0D
	jsr putc
@jump_linefeed:
	iny
	cpy ZP_PTR
	bne @loop
	rts

	
print_windmill:
	and #$3
	tay
	lda windmill, y
	jsr putc
	lda #$08
	jsr putc
	rts



windmill:
	.byte "-\|/"

welcome_message:
	.byte "dos v2.0", $0A, $0D, $00


help_message:
	.byte "sorry, you're on your own...", $0A, $0D, $00

file_not_found_message:
	.byte "file not found.", $0A, $0D, $00

