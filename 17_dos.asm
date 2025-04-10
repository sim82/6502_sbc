
.IMPORT put_newline, uart_init, putc, getc, fputc, fgetc, fgetc_nonblocking, fpurge, print_hex16, print_hex8
.import fgetc_buf, open_file_nonpaged
.import file_open_raw
.import reset_tokenize, read_token, retire_token, terminate_token
.import read_file_paged
.import print_message, decode_nibble, decode_nibble_high
.import load_relocatable_binary
.import init_pagetable, alloc_page, alloc_page_span, free_page_span, free_user_pages
.import cmd_help_str, cmd_help, cmd_alloc_str, cmd_alloc, cmd_j_str, cmd_j, cmd_r_str, cmd_r, cmd_ra_str, cmd_ra, cmd_m_str, cmd_m, cmd_fg_str, cmd_fg
.export get_argn, get_arg, load_binary, jsr_receive_pos, welcome_message, back_to_dos_message, rand_8
.include "17_dos.inc"
.include "os.inc"

RESIDENT_STATE_NONE = $00
RESIDENT_STATE_INITIAL = $01
RESIDENT_STATE_RUN = $02
RESIDENT_STATE_SLEEP = $03



UART_CLK = 3686400 ; 3.6864 MHz

.macro uart_start_timer timer_hz
	lda #%01110000
	sta IO_UART2_ACR

	; setup timer divider low / high bytes
	lda #((UART_CLK / (timer_hz * 16)) .MOD 256)
	sta IO_UART2_CTPL
	lda #((UART_CLK / (timer_hz * 16)) / 256)
	sta IO_UART2_CTPU

	; start timer
	lda IO_UART2_CSTA
.endmacro

.macro uart_start_timer_high timer_hz
	lda #%01100000
	sta IO_UART2_ACR
	; setup timer divider low / high bytes
	lda #((UART_CLK / (timer_hz)) .MOD 256)
	sta IO_UART2_CTPL
	lda #((UART_CLK / (timer_hz)) / 256)
	sta IO_UART2_CTPU

	; start timer
	lda IO_UART2_CSTA
.endmacro
.CODE
	; init local vars
	lda #$00
	sta INPUT_LINE_PTR
	sta USER_PROCESS
	sta INPUT_CHAR
	sta IRQ_TIMER
	

	sei
	
	jsr uart_init
	lda #%00001010
	sta IO_UART2_IMR

	uart_start_timer 10 

	; lda IO_UART2_CSTO
	
	lda #<irq
	sta $fdfe
	
	lda #>irq
	sta $fdfe+1

	; jmp @skip_init
	jsr init_pagetable
	
; @skip_init:
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
	; check if there is a resident process
	lda RESIDENT_STATE
	beq @no_resident_run

	; RESIDENT_STATE_INITIAL-> send OS_EVENT_INIT 
	cmp #RESIDENT_STATE_INITIAL
	bne @not_init
	lda #OS_EVENT_INIT
	sta RESIDENT_EVENT
	jsr run_resident

	; if resident state == 0 after run_resident -> process exited. go right to sleep

	lda RESIDENT_STATE
	beq @sleep
	
	; otherwise promote it to a resident process
	lda #RESIDENT_STATE_RUN
	sta RESIDENT_STATE
	jmp @sleep

@not_init:
	cmp #RESIDENT_STATE_RUN
	bne @no_resident_run
	
	; check timer
	
	lda IRQ_TIMER
	beq @no_timer
	lda #OS_EVENT_TIMER
	sta RESIDENT_EVENT
	jsr run_resident
	lda #$00
	sta IRQ_TIMER
@no_timer:
	lda INPUT_CHAR
	; go right back to sleep if there is no input char (wakeup was due to timer)
	; TODO: check / log if there are 'spurious' wakeups...
	beq @sleep
	; check ctrl-z	
	cmp #$1a
	bne @no_to_background
	lda #RESIDENT_STATE_SLEEP
	sta RESIDENT_STATE 
	jsr put_newline
	jsr print_prompt
	jmp @sleep
	
@no_to_background:
	; check ctrl-c
	cmp #$03
	bne @no_cancel
	; cleanup process
	; meeeep! redundant!
	lda RECEIVE_POS + 1
	jsr free_page_span
	jsr free_user_pages
	jsr clear_resident
	jsr put_newline
	jsr print_prompt
	jmp @sleep

@no_cancel:
	; send input char as OS_EVENT_KEY
	sta RESIDENT_EVENTDATA
	lda #OS_EVENT_KEY
	sta RESIDENT_EVENT
	jsr run_resident
	; clear input char after one key event was sent
	lda #$00
	sta INPUT_CHAR
	jmp @sleep

@no_resident_run:
	; if no resident program is running, process input with command processor
	lda INPUT_CHAR
	beq @sleep
	jsr process_input
	lda #$00
	sta INPUT_CHAR
	lda RESIDENT_STATE
	cmp #RESIDENT_STATE_INITIAL
	beq @skip_sleep ; @wait_loop is too far away for an indirect jump...

@sleep:
	wai ; look at me, I sleep all day like the big CPUs...
@skip_sleep:
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
	; non-zero return code -> keep resident
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
	pha
	lda IO_UART2_ISR
	sta IRQ_TMP_A
	and #%00000010
	beq @no_char
	jsr getc
	bcs @use_char

	lda #$00
@use_char:
	sta INPUT_CHAR

@no_char:
	lda IRQ_TMP_A
	and #%00001000
	sta IRQ_TIMER

@no_timer:
	lda IO_UART2_CSTO
	pla
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
	lda #RESIDENT_STATE_INITIAL
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
	
rand_8:
	tya
	pha
	txa
	pha
	LDA	RAND_SEED		; get seed
	AND	#$b8		; mask non feedback bits
				; for maximal length run with 8 bits we need
				; taps at b7, b5, b4 and b3
	LDX	#$05		; bit count (shift top 5 bits)
	LDY	#$00		; clear feedback count
@f_loop:
	ASL	A		; shift bit into carry
	BCC	@bit_clr	; branch if bit = 0

	INY			; increment feedback count (b0 is XOR all the	
				; shifted bits from A)
@bit_clr:
	DEX			; decrement count
	BNE	@f_loop		; loop if not all done

@no_clr:
	TYA			; copy feedback count
	LSR	A		; bit 0 into Cb
	LDA	RAND_SEED	; get seed back
	ROL	A		; rotate carry into byte
	STA	RAND_SEED	; save number as next seed
	pla
	tax
	pla
	tay
	lda RAND_SEED
	RTS			; done

 
windmill:
	.byte "-\|/"

welcome_message:
	.byte "dos v3.3", $0A, $0D, $00



back_to_dos_message:
	.byte "Back in control..", $0A, $0D, $00
