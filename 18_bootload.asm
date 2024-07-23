
.AUTOIMPORT +
.INCLUDE "std.inc"
.SEGMENT "VECTORS"
; change for ram build!
	.WORD $FF00
	; .WORD $3000




ZP_PTR = $80

IO_ADDR = ZP_PTR + 2

RECEIVE_POS = IO_ADDR + 2
RECEIVE_SIZE = RECEIVE_POS + 2


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


; store 16bit value (addr) into two bytes of memory at dest
.macro store_address addr, dest
	lda #<addr
	sta dest
	lda #>addr
	sta dest + 1
.endmacro

.CODE
	; init display
	jsr check_busy
	lda #%00111000      ; 8bit, two row, default font?
	sta IO_DISP_CTRL

	jsr check_busy
	lda #$1             ; clear display
	sta IO_DISP_CTRL

 	jsr check_busy
	lda #%00001100; display on, cursor/blink off
	sta IO_DISP_CTRL

	; init uart channel 2
	; Bit 7: Select CR = 0
	; Bit 6: CDR/ACR (don't care)
	; Bit 5: Num stop bits (0=1, 1-2)
	; Bit 4: Echo mode (0=disabled, 1=enabled)
	; Bit 3-0: baud divisor (1110 = 3840)
	; write CR
	lda #%00001110
	; sta IO_UART_CR1
	sta IO_UART_CR2

	; Bit 7: Select FR = 1
	; Bit 6,5: Num Bits (11 = 8)
	; Bit 4,3: Parity mode (don't care)
	; Bit 2: Parity Enable / Disable (1/0)
	; Bit 1,0: DTR/RTS control (don't care)
	; write FR
	lda #%11100000
	; sta IO_UART_FR1
	sta IO_UART_FR2

	lda #%11000001
	; sta IO_UART_IER1
	sta IO_UART_IER2


	store_address welcome_message, ZP_PTR
	jsr print_disp
; purge any channel2 input buffer before starting IO
	jsr purge_channel2_input
	ldy #$00
@loop:
	lda filename, y
	iny
	jsr putc2
	bne @loop
	jsr load_binary
	bcc @file_error
	jmp (RECEIVE_POS)

@file_error:
	store_address file_not_found_message, ZP_PTR
	jsr print_disp
@end_loop:
	nop
	jmp @end_loop


check_busy:
@loop:
	lda IO_DISP_CTRL
	and #$80
	bne @loop

	rts


load_binary:
	; meaning of IO_ADDR vs RECEIVE_POS: 
	;  - IO_ADDR: in ZP, used for indirect addressing and modified during read
	;  - RECEIVE_POS: no need to be in ZP, used as entry point to program after read

	jsr getc2	; read target address low byte
	sta RECEIVE_POS
	sta IO_ADDR
	jsr getc2	; and high byte
	sta RECEIVE_POS + 1	
	sta IO_ADDR + 1
	; check for file error: target addr high $ff (this is always rom)
	; low byte check not necessary
	cmp #$FF
	bne @no_error
	; fell through -> error
	clc
	rts

@no_error:
	jsr getc2	; read size low byte
	sta RECEIVE_SIZE
	; jsr print_hex8
	jsr getc2	; and high byte
	sta RECEIVE_SIZE + 1

	; no space for size check...
	;
	; outer loop over all received pages
	; pages are loaded into IO_BUFFER one by one
	;
@load_page_loop:
	; request next page
	lda #'b'		; send 'b' command to signal 'send next page'
	jsr putc2
	ldy #$00		; y: count byte inside page
	lda RECEIVE_SIZE + 1
	beq @non_full_page

	and #$03
	tax
	lda windmill, x
	sta IO_DISP_DATA
	; jsr check_busy
	; ldx RECEIVE_SIZE + 1	; use receive size high byte to determine if a full page shall be read


	;
	; full page case: exactly 256 bytes
	;
@loop_full_page:
	jsr getc2	; recv next byte
	sta (IO_ADDR), y	;  and store to (IO_ADDR) + y
	iny
	bne @loop_full_page	; end on y wrap around

	; interleave lcd delete (for windmill) with uart io to save need disp_busy call...
	lda #%10000101
	sta IO_DISP_CTRL
	dec RECEIVE_SIZE + 1	; dec remaining size 
	inc IO_ADDR + 1

	jmp @load_page_loop	; continue with next page

	
	;
	; reminder, always less than 256 bytes
	;
@non_full_page:
@non_full_page_loop:
	cpy RECEIVE_SIZE	; compare with lower byte of remaining size
	beq @end
	jsr getc2	; recv next byte
	sta (IO_ADDR), y	;  and store to TARGET_ADDR + y
	iny
	jmp @non_full_page_loop

@end:
	
	sec
	rts

	
	



putc2:
	pha
@loop:
	lda IO_UART_ISR2
	and #%01000000
	beq @loop
	pla
	sta IO_UART_TDR2
	rts

getc2:
	lda IO_UART_ISR2
	and #%00000001
	beq getc2
	lda IO_UART_RDR2
shared_rts:
	rts
	
; getc2:
; 	jsr getc2_nonblocking
; 	bcc getc2
; 	rts

; getc2_nonblocking:
; @loop:
; 	; check transmit data register empty
; 	lda IO_UART_ISR2
; 	and #%00000001
; 	beq @no_keypress
; 	lda IO_UART_RDR2
;         sec
; 	rts

; @no_keypress:
;         clc
; 	rts

purge_channel2_input:
; purge any channel2 input buffer
	lda IO_UART_ISR2
	and #%00000001
	beq shared_rts
	lda IO_UART_RDR2
	jmp purge_channel2_input
	; jsr getc2_nonblocking
	; bcs purge_channel2_input
	; rts

print_disp:
	ldy #$00
@loop:
	jsr check_busy
	lda (ZP_PTR), y
	beq @done
	sta IO_DISP_DATA 
	iny
	jmp @loop
@done:
	rts


	
welcome_message:
	.byte "bl1.1", $00


file_not_found_message:
	.byte "e:n", $00

filename:
 	.byte "o.b", $00

windmill:
	.byte $5c, "|/-"
