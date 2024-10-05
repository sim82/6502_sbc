
.IMPORT put_newline, uart_init, putc, getc, putc2, getc2, getc2_nonblocking, purge_channel2_input, print_hex16
.INCLUDE "std.inc"

INPUT_LINE = $0200				; address of input line
INPUT_LINE_LEN = $50				; capacity of input line
INPUT_LINE_PTR = INPUT_LINE + INPUT_LINE_LEN	; address of current input line ptr 
						; (relative to address of input line)

NEXT_TOKEN_PTR   = INPUT_LINE_PTR + 1
NEXT_TOKEN_END   = NEXT_TOKEN_PTR + 1

RECEIVE_POS = NEXT_TOKEN_END + 1
RECEIVE_SIZE = RECEIVE_POS + 2
IO_FUN = RECEIVE_SIZE + 2

ZP_PTR = $80

IO_ADDR = ZP_PTR + 2
FLETCH_1 = IO_ADDR + 2
FLETCH_2 = FLETCH_1 + 1

IO_BUFFER = $0300

.macro set_ptr src
	ldx #<src
	stx ZP_PTR
	ldx #>src
	stx ZP_PTR + 1
.endmacro

.macro dispatch_command cmd_ptr, dest
.local @next
	set_ptr cmd_ptr
	jsr compare_token
	bcc @next
	jsr dest
	jmp @cleanup
@next:
.endmacro

.macro print_message_from_ptr src
	lda #<src
	ldx #>src
	jsr print_message
.endmacro

; store 16bit value (addr) into two bytes of memory at dest
.macro store_address addr, dest
	lda #<addr
	sta dest
	lda #>addr
	sta dest + 1
.endmacro

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

	lda INPUT_LINE, y
	; jsr putc
	cmp (ZP_PTR), y
	bne @mismatch
	iny
	jmp @loop

@found:
	sec
	rts
	
@mismatch:
	clc
	rts
	
cmd_help_str:
	.byte "help"
cmd_help:
	print_message_from_ptr welcome_message
	print_message_from_ptr help_message
	rts

cmd_ls_str:
	.byte "ls"
cmd_ls:
	print_message_from_ptr help_message
	rts


cmd_cat_str:
	.byte "cat"
cmd_cat:
	print_message_from_ptr @purrrr
	jsr retire_token
	jsr read_token
	jsr purge_channel2_input
	lda #'r'
	jsr putc2
	ldy NEXT_TOKEN_PTR
@send_filename_loop:
	cpy NEXT_TOKEN_END
	beq @end_of_filename
	lda INPUT_LINE, y
	jsr putc2
	iny
	jmp @send_filename_loop
@end_of_filename:
	lda #$00
	jsr putc2
	store_address IO_BUFFER, IO_ADDR
	store_address cat_iobuffer, IO_FUN
	jsr read_file_paged
	rts
@purrrr:
	.byte "purrrr", $0A, $0D, $00

cmd_bench_str:
	.byte "bench"
cmd_bench:
	jsr retire_token
	jsr read_token
	jsr purge_channel2_input
	lda #'r'
	jsr putc2
	ldy NEXT_TOKEN_PTR
@send_filename_loop:
	cpy NEXT_TOKEN_END
	beq @end_of_filename
	lda INPUT_LINE, y
	jsr putc2
	iny
	jmp @send_filename_loop
@end_of_filename:
	lda #$00
	jsr putc2
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
	.byte "echo"
cmd_echo:
	jsr getc
	bcc cmd_echo
	jsr putc
	; endless loop
	jmp cmd_echo


exec_input_line:
	jsr getc2_nonblocking
	bcs exec_input_line
	jsr purge_channel2_input
	jsr reset_tokenize
	jsr read_token
	bcs @dispatch_builtin
	jmp @cleanup

@dispatch_builtin:
	dispatch_command cmd_help_str, cmd_help
	dispatch_command cmd_ls_str, cmd_ls
	dispatch_command cmd_cat_str, cmd_cat
	dispatch_command cmd_bench_str, cmd_bench
	dispatch_command cmd_echo_str, cmd_echo
	; fall through. successfull commands jump to @cleanup from macro
; @end:
; purge any channel2 input buffer before starting IO
	jsr purge_channel2_input
	lda #'o'
	jsr putc2
	ldy #$0
@send_filename_loop:
	cpy NEXT_TOKEN_END
	beq @end_of_filename
	lda INPUT_LINE, y
	jsr putc2
	iny
	jmp @send_filename_loop
@end_of_filename:
	lda #$00
	jsr putc2
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

; tokenizer
; in-place tokenize content of input line. Tokens are separated by space character.
; The tokenizer will not modify the input line but keep track of the current token
; in NEXT_TOKEN_PTR and NEXT_TOKEN_END:
;    NEXT_TOKEN_PTR: start of next token (relative to address of INPUT_LINE)
;    NEXT_TOKEN_END: end of next token (i.e. first char after token) this can either be a space or then end of input line
;
; normal usage:
; 1. call reset_tokenize to start tokenizer at start of input line
; 2. call read_token
;	if a token can be read NEXT_TOKEN_PTR and NEXT_TOKEN_END are set up and carry is set
;	otherwise carry is cleared (i.e. there are no more tokens) -> end loop
; 3. call retire token. This will advance NEXT_TOKEN_PTR to NEXT_TOKEN_END
; 	repeat at point (2) (i.e. the next read_token call)
reset_tokenize:
	lda #$00
	sta NEXT_TOKEN_PTR
	sta NEXT_TOKEN_END
	rts

read_token:
	; skip whitespace
	ldy NEXT_TOKEN_PTR
	cpy INPUT_LINE_PTR	; check for end of line
	beq @end_of_line

	lda INPUT_LINE, y	; read character
	cmp #$20		; and check for space
	bne @after_space
	inc NEXT_TOKEN_PTR
	jmp read_token		; there was a space -> continue loop
	
@end_of_line:
	clc			; report no success: end of line was hit while looking for space
	rts

	; at this point NEXT_TOKEN_PTR must point at a valid char
@after_space:
	ldy NEXT_TOKEN_PTR
@in_token_loop:
	iny			; pre-increment (we are sure that there was a char at Y
				;		otherwise skip space code would already have returned)

	cpy INPUT_LINE_PTR	; check for line end
	beq @end_of_token	; 	handle like normal token end 
	lda INPUT_LINE, y	; check for space
	cmp #$20
	beq @end_of_token	; space also means end of token
	jmp @in_token_loop

@end_of_token:
	sty NEXT_TOKEN_END	; Y points to first char after token (either space or end of line)
	cpy NEXT_TOKEN_PTR
	; clc
	; beq @token_empty
	sec			; report success
; @token_empty:
	rts


retire_token:
	lda NEXT_TOKEN_END	
	sta NEXT_TOKEN_PTR	; advance topen pointer to previous token end ptr
	lda #$00
	sta NEXT_TOKEN_END	; invalidate previous token end ptr
	rts

load_binary:
	; meaning of IO_ADDR vs RECEIVE_POS: 
	;  - IO_ADDR: in ZP, used for indirect addressing and modified during read
	;  - RECEIVE_POS: no need to be in ZP, used as entry point to program after read

	lda #0
	sta FLETCH_1
	sta FLETCH_2
	jsr getc2	; read target address low byte
	sta RECEIVE_POS
	sta IO_ADDR
	jsr getc2	; and high byte
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

; IO_ADDR: 16bit destination address
; IO_FUN: address of per-page io completion function (after a page was loaded into (IO_ADDR)).
;         (IO_FUN) is called with subroutine semantics (i.e. do rts to return), X register contains size of
;         current page ($00 means full page). Code in IO_FUN is allowed to modify IO_ADDR, which enables easy loding in to
;         consecutove pages (use e.g. for binary loading)
read_file_paged:
	jsr getc2	; read size low byte
	sta RECEIVE_SIZE
	; jsr print_hex8
	jsr getc2	; and high byte
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
	; jsr putc2

	ldy #$00		; y: count byte inside page
	ldx RECEIVE_SIZE + 1	; use receive size high byte to determine if a full page shall be read
	beq @non_full_page

	lda #'b'		; send 'b' command to signal 'send next page'
	jsr putc2
	;
	; full page case: exactly 256 bytes
	;
@loop_full_page:
	jsr getc2	; recv next byte
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
	jsr putc2
@non_full_page_loop:
	cpy RECEIVE_SIZE	; compare with lower byte of remaining size
	beq @end
	jsr getc2	; recv next byte
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
	
print_windmill:
	and #$3
	tay
	lda windmill, y
	jsr putc
	lda #$08
	jsr putc
	rts


; low in a, high in x,
print_message:
	sta ZP_PTR
	stx ZP_PTR + 1
	ldy #$00
@loop:
	lda (ZP_PTR), y
	beq @end
	jsr putc
	iny
	jmp @loop
@end:
	rts


windmill:
	.byte "-\|/"

welcome_message:
	.byte "dos v1.3", $0A, $0D, $00


help_message:
	.byte "sorry, you're on your own...", $0A, $0D, $00

file_not_found_message:
	.byte "file not found.", $0A, $0D, $00

