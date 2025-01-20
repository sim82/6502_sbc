
.IMPORT put_newline, uart_init, putc, getc, fputc, fgetc, fgetc_nonblocking, fpurge, print_hex16, print_hex8
.import fgetc_buf, open_file_nonpaged
.import file_open_raw
.import reset_tokenize, read_token, retire_token, terminate_token
.import read_file_paged
.import print_message, decode_nibble, decode_nibble_high
.import load_relocatable_binary
.import init_pagetable, alloc_page, alloc_page_span, free_page_span, free_user_pages
.import cmd_help_str, cmd_help, cmd_alloc_str, cmd_alloc, cmd_j_str, cmd_j, cmd_r_str, cmd_r, cmd_ra_str, cmd_ra, cmd_m_str, cmd_m, cmd_fg_str, cmd_fg
.export get_argn, get_arg, load_binary, jsr_receive_pos, welcome_message, back_to_dos_message
.INCLUDE "17_dos.inc"



.CODE
	; init local vars
	lda #$00
	sta INPUT_LINE_PTR
	sta USER_PROCESS
	sta INPUT_CHAR
	

	sei
	
	jsr uart_init
	lda #%00000010
	sta IO_UART2_IMR

	lda #<irq
	sta $fdfe
	
	lda #>irq
	sta $fdfe+1
	jsr init_pagetable
	
	jsr clear_resident

; @loop:
; 	jsr getc
; 	bcc @loop
; 	jsr print_hex8
; 	jmp @loop
; @loop:
; 	jsr getc
; 	bcc @loop
; 	jsr putc
; 	jmp @loop

	cli
	jsr put_newline
	print_message_from_ptr welcome_message

	lda #'>'
	jsr putc

@wait_loop:
	lda RESIDENT_STATE
	beq @no_resident

	cmp #$01
	bne @not_init
	lda #$00
	sta RESIDENT_EVENTDATA
	jsr run_resident

	lda RESIDENT_STATE
	beq @sleep
	
	lda #$02
	sta RESIDENT_STATE

@not_init:
	cmp #$02
	bne @no_resident
	
	lda INPUT_CHAR
	
	cmp #$03
	bne @no_interrupt
	lda #$03
	sta RESIDENT_STATE 
	jsr put_newline
	jsr print_prompt
	jmp @sleep
	
@no_interrupt:
	sta RESIDENT_EVENTDATA
	lda #$01
	sta RESIDENT_EVENT
	jsr run_resident
	jmp @sleep

@no_resident:
	lda INPUT_CHAR
	beq @sleep
	jsr process_input
	lda RESIDENT_STATE
	cmp #$01
	beq @wait_loop

@sleep:
	lda #%00001111
	sta IO_GPIO0
	wai ; look at me, I sleep all day like the big CPUs...
	lda #%00000011
	sta IO_GPIO0
	jmp @wait_loop

run_resident:
	lda #$00
	sta RESIDENT_RETURN
	lda #$ff
	sta USER_PROCESS
	jsr jsr_receive_pos
	lda #$00
	sta USER_PROCESS
	lda RESIDENT_RETURN
	bne @keep_resident
	jsr clear_resident
	lda RECEIVE_POS + 1
	jsr free_page_span
	jsr free_user_pages
	jsr clear_resident
	jmp @exit ; skip printing '*'
	
@keep_resident:
	lda #'*'
	jsr putc
	rts
	
@exit:
	print_message_from_ptr back_to_dos_message

	jsr print_prompt
	rts

jsr_resident:
	jmp (RESIDENT_ENTRYPOINT)
	jmp jsr_resident

clear_resident:
	lda #$00
	sta RESIDENT_STATE
	; sta RESIDENT_ENTRYPOINT
	; sta RESIDENT_ENTRYPOINT + 1
	rts

irq:
; 	meeeeeep
; 	this is not working. just put char in a queue (or buffer) and let the mainloop decide what to do with it...
; 	lda RESIDENT_STATE
; 	beq @no_resident
; 	cmp #$02
; 	bne @skip
; 	jsr getc
; 	sta RESIDENT_EVENTDATA
; 	jmp @skip

; @no_resident:
; 	jsr getc
; 	bcc @skip
; 	jsr process_input
; @skip:
	jsr getc
	bcs @use_char

	lda #$00
@use_char:
	sta INPUT_CHAR
	rti

print_prompt:
	lda RESIDENT_STATE
	beq @no_resident
	lda #'*'
	jsr putc
@no_resident:
	lda #'>'
	jsr putc
	rts

read_input:
	jsr getc
	bcc read_input 		; busy wait for character
	; pha
	; jsr print_hex8
	; jsr put_newline
	; pla
process_input:
	cmp #$0a 		; ignore LF / \n
	beq read_input
	cmp #$0d 		; enter key is CR / \r 
	bne @no_enter_key
	jsr put_newline		; handle enter: - put newline
	jsr exec_input_line     ;               - execute input line
	jsr print_prompt
	rts
	
@no_enter_key:
	cmp #$08		; handle backspace
	bne @normal_char
	ldy INPUT_LINE_PTR	; check if input line is empty -> ignore backspace
	beq @exit
	dec INPUT_LINE_PTR	; delete last char (dec ptr)

	; rub-out character on terminal
	jsr putc		; send the backspace (move cursor back)
	lda #' '		; overwrite with space
	jsr putc
	lda #$08		; send another backspace to move cursor back onto space
	jsr putc
	; jmp mainloop

@exit:
	rts
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
	

jsr_receive_pos:
	jmp (RECEIVE_POS)
	jmp jsr_receive_pos

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
	dispatch_command cmd_r_str, cmd_r
	dispatch_command cmd_m_str, cmd_m
	dispatch_command cmd_j_str, cmd_j
	dispatch_command cmd_alloc_str, cmd_alloc
	dispatch_command cmd_ra_str, cmd_ra
	dispatch_command cmd_fg_str, cmd_fg

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
	lda RECEIVE_POS
	sta RESIDENT_ENTRYPOINT
	lda RECEIVE_POS + 1
	sta RESIDENT_ENTRYPOINT + 1
	lda #$01
	sta RESIDENT_STATE
	
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
	.byte "dos v3.2", $0A, $0D, $00



back_to_dos_message:
	.byte "Back in control..", $0A, $0D, $00
