
.IMPORT put_newline, uart_init, putc, getc, fputc, fgetc, fgetc_nonblocking, fpurge, print_hex16, print_hex8
.import fgetc_buf, open_file_nonpaged
.import file_open_raw
.import reset_tokenize, read_token, retire_token, terminate_token
.import read_file_paged
.import print_message, decode_nibble, decode_nibble_high
.import load_relocatable_binary
.import init_pagetable, alloc_page, alloc_page_span
.export get_argn, get_arg
.INCLUDE "17_dos.inc"



.CODE
	; init local vars
	lda #$00
	sta INPUT_LINE_PTR

	
	jsr uart_init
	jsr init_pagetable

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
	jsr terminate_token
	lda NEXT_TOKEN_PTR
	ldx #>INPUT_LINE
	
	jsr load_relocatable_binary
	rts

@error:
	print_message_from_ptr @error_msg
	rts
@purrrr:
	.byte "stream...", $0A, $0D, $00

@error_msg:
	.byte "error.", $0A, $0D, $00


; m - monitor
cmd_m_str:
	.byte "m", $00
cmd_m:
	jsr retire_token
	jsr read_token
	bcc @no_addr

	ldy NEXT_TOKEN_PTR
	
	lda INPUT_LINE, y
	jsr decode_nibble_high
	bcc @no_addr
	sta A_TEMP

	iny
	lda INPUT_LINE, y
	jsr decode_nibble
	bcc @no_addr

	ora A_TEMP
	sta MON_ADDRH

; if there was a valid high part of an address given, already set the low mon addr to $00.
; this way the lower part is optional, allowing e.g. 'm 02' to monitor the second page. 
	lda #$00
	sta MON_ADDRL

	iny
	lda INPUT_LINE, y
	jsr decode_nibble_high
	bcc @no_addr
	sta A_TEMP

	iny
	lda INPUT_LINE, y
	jsr decode_nibble
	bcc @no_addr

	ora A_TEMP
	sta MON_ADDRL
	
@no_addr:
	; ldx MON_ADDRH
	; lda MON_ADDRL
	; jsr print_hex16
	; jsr put_newline
	ldy #0

	jmp @newline
@loop:
	lda (MON_ADDRL), y
	
	jsr print_hex8

	iny
	beq @end

	tya
	and #$f
	beq @newline ; mod 16 == 0 -> print newline
	cmp #$8 ; mod 16 == 8 -> print extra separator
	bne @skip_extra_sep
	lda #' '
	jsr putc
@skip_extra_sep:
	lda #' '
	jsr putc
	jmp @loop

@newline:
	jsr put_newline
	tya
	clc
	adc MON_ADDRL

	ldx MON_ADDRH
	jsr print_hex16
	lda #' '
	jsr putc
	jsr putc
	jmp @loop


	
; 	ldx #$10
; ; @outer_loop:
; 	ldy #0
; @loop:
; 	cpy #16
; 	beq @end
	
; 	lda (ZP_PTR), y
; 	jsr print_hex8
; 	lda #' '
; 	jsr putc
; 	iny
; 	jmp @loop
@end:
	inc MON_ADDRH
	; jsr put_newline
	; inc ZP_PTR + 1
	; dex
	; bne @outer_loop
	
	rts

; j - jmp
cmd_j_str:
	.byte "j", $00
cmd_j:
	jsr jsr_receive_pos
	print_message_from_ptr back_to_dos_message
	rts
	


jsr_receive_pos:
	jmp (RECEIVE_POS)
	jmp jsr_receive_pos

; alloc - test memory allocator
cmd_alloc_str:
	.byte "alloc", $00
cmd_alloc:
	lda #5
	jsr alloc_page_span
	bcc @end
	jsr print_hex8
	jsr put_newline
@end:
	rts

; ra - run absolute
cmd_ra_str:
	.byte "ra", $00
cmd_ra:
; straight copy of the old 'execute binary' code.
	jsr retire_token
	jsr read_token
; purge any channel2 input buffer before starting IO
	jsr fpurge
	lda #'o'
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

	; put receive pos into monitor address, for inspection after reset
	lda RECEIVE_POS + 1
	sta MON_ADDRH
	lda RECEIVE_POS
	sta MON_ADDRL
	jmp (RECEIVE_POS)

@file_error:
	print_message_from_ptr file_not_found_message


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

exec_input_line:
	; add null termination at end of input line to make parsing more convenient
	ldx INPUT_LINE_PTR
	lda #$00
	sta INPUT_LINE, x
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
	dispatch_command cmd_bench_str, cmd_bench
	dispatch_command cmd_echo_str, cmd_echo
	dispatch_command cmd_r_str, cmd_r
	dispatch_command cmd_m_str, cmd_m
	dispatch_command cmd_j_str, cmd_j
	dispatch_command cmd_alloc_str, cmd_alloc
	dispatch_command cmd_ra_str, cmd_ra

	; fall through. successfull commands jump to @cleanup from macro
; @end:

	lda #$00
	sta ARGC
		
@arg_loop:
	ldy ARGC
	inc ARGC
	lda NEXT_TOKEN_PTR
	sta ARGV, y
	jsr print_hex8
	jsr terminate_token
	jsr retire_token
	jsr read_token
	bcs @arg_loop

 	jsr put_newline
	lda ARGV
	ldx #>INPUT_LINE
	jsr load_relocatable_binary
	bcc @cleanup
	jsr jsr_receive_pos
	print_message_from_ptr back_to_dos_message
@cleanup:

	ldy #$0
	sty INPUT_LINE_PTR
	jsr put_newline
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


get_argn:
	lda ARGC
	rts

get_arg:
	cmp ARGC
	bpl @out_of_range

	tax
	lda ARGV, x
	ldx #>INPUT_LINE
	sec
	rts

@out_of_range:
	clc
	rts
	
 
windmill:
	.byte "-\|/"

welcome_message:
	.byte "dos v3.0", $0A, $0D, $00


help_message:
	.byte "sorry, you're on your own...", $0A, $0D, $00

file_not_found_message:
	.byte "file not found.", $0A, $0D, $00

back_to_dos_message:
	.byte "Back in control..", $0A, $0D, $00
