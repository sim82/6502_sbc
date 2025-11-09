
.IMPORT put_newline, uart_init, putc, getc, fputc, fgetc, fgetc_nonblocking, fpurge, print_hex16, print_hex8
.import fgetc_buf, open_file_nonpaged
.import file_open_raw
.import reset_tokenize, read_token, retire_token, terminate_token
.import read_file_paged
.import print_message, decode_nibble, decode_nibble_high
.import load_relocatable_binary
.import alloc_page, alloc_page_span, free_page_span, free_user_pages
.import load_binary, jsr_receive_pos, welcome_message, back_to_dos_message
.export cmd_help_str, cmd_help, cmd_m_str, cmd_m, cmd_j_str, cmd_j, cmd_alloc_str, cmd_alloc, cmd_ra_str, cmd_ra, cmd_r_str, cmd_r, cmd_fg_str, cmd_fg
.INCLUDE "17_dos.inc"

	
cmd_help_str:
	.byte "help", $00
cmd_help:

	; jsr fgetc
	; jsr print_hex8
	; jmp cmd_help
	; lda #00
	lda #00
; @loop:
; 	sta IO_GPIO0
; 	inc
; 	jmp @loop
	ldy #0
@loop2:
	sty IO_UART2_GPR
	cpy IO_UART2_GPR
	; bne @error
	sta IO_GPIO0
	sty IO_GPIO0
	iny
	jmp @loop2
	; print_message_from_ptr welcome_message
	; print_message_from_ptr help_message
	rts
@error:
	lda #%01010101
	sta IO_GPIO0
	jmp @error


; r - streamed binary load / relocate
cmd_r_str:
	.byte "r", $00
cmd_r:
	print_message_from_ptr @purrrr
	jsr retire_token
	jsr read_token
	jsr terminate_token
	lda oss_next_token_ptr
	ldx #>oss_input_line
	
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

	ldy oss_next_token_ptr
	
	lda oss_input_line, y
	jsr decode_nibble_high
	bcc @no_addr
	sta zp_a_temp

	iny
	lda oss_input_line, y
	jsr decode_nibble
	bcc @no_addr

	ora zp_a_temp
	sta zp_mon_addrh

; if there was a valid high part of an address given, already set the low mon addr to $00.
; this way the lower part is optional, allowing e.g. 'm 02' to monitor the second page. 
	lda #$00
	sta zp_mon_addrl

	iny
	lda oss_input_line, y
	jsr decode_nibble_high
	bcc @no_addr
	sta zp_a_temp

	iny
	lda oss_input_line, y
	jsr decode_nibble
	bcc @no_addr

	ora zp_a_temp
	sta zp_mon_addrl
	
@no_addr:
	; ldx zp_mon_addrh
	; lda zp_mon_addrl
	; jsr print_hex16
	; jsr put_newline
	ldy #0

	jmp @newline
@loop:
	lda (zp_mon_addrl), y
	
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
	adc zp_mon_addrl

	ldx zp_mon_addrh
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
	
; 	lda (zp_ptr), y
; 	jsr print_hex8
; 	lda #' '
; 	jsr putc
; 	iny
; 	jmp @loop
@end:
	inc zp_mon_addrh
	; jsr put_newline
	; inc zp_ptr + 1
	; dex
	; bne @outer_loop
	
	rts

; j - jmp
cmd_j_str:
	.byte "j", $00
cmd_j:
	lda #$ff
	sta oss_user_process
	jsr jsr_receive_pos
	lda #$00
	sta oss_user_process
	print_message_from_ptr back_to_dos_message
	rts
	

; alloc - test memory allocator
cmd_alloc_str:
	.byte "alloc", $00
cmd_alloc:
; 	lda #5
; 	jsr alloc_page_span
; 	bcc @end

; 	pha
; 	jsr print_hex8
; 	jsr put_newline
; 	pla
; 	jsr free_page_span
	
; 	bcc @end

; 	jsr print_hex8
; 	jsr put_newline
; @end:
	rts

; ra - run absolute
cmd_ra_str:
	.byte "ra", $00
cmd_ra:
; straight copy of the old 'execute binary' code.
	sei
	jsr retire_token
	jsr read_token
; purge any channel2 input buffer before starting IO
	jsr fpurge
	lda #'o'
	jsr fputc
	ldy oss_next_token_ptr
@send_filename_loop:
	cpy oss_next_token_end
	beq @end_of_filename
	lda oss_input_line, y
	jsr fputc
	iny
	jmp @send_filename_loop
@end_of_filename:
	lda #$00
	jsr fputc
	jsr load_binary
	bcc @file_error
	lda oss_receive_pos
	ldx oss_receive_pos + 1
	jsr print_hex16
	jsr put_newline
	ldy 0
@delay:
	iny
	bne @delay

	; put receive pos into monitor address, for inspection after reset
	lda oss_receive_pos + 1
	sta zp_mon_addrh
	lda oss_receive_pos
	sta zp_mon_addrl
	jmp (oss_receive_pos)

@file_error:
	print_message_from_ptr file_not_found_message
	rts


; fg - foreground
cmd_fg_str:
	.byte "fg", $00
cmd_fg:
	lda oss_resident_state
	cmp #$03
	bne @no_background
	lda #$02
	sta oss_resident_state
	rts
	
@no_background:
	print_message_from_ptr no_background_message
	rts



no_background_message:
	.byte "no background process.", $0A, $0D, $00

help_message:
	.byte "sorry, you're on your own...", $0A, $0D, $00

file_not_found_message:
	.byte "file not found.", $0A, $0D, $00

