
.AUTOIMPORT +
.INCLUDE "std.inc"
.SEGMENT "VECTORS"
; change for ram build!
	.WORD $FF00
	.WORD irq
	; .WORD $3000




ZP_PTR = $80


IO_ADDR = ZP_PTR + 2

RECEIVE_POS = IO_ADDR + 2
RECEIVE_SIZE = RECEIVE_POS + 2

BLINKENLIGHT = RECEIVE_SIZE + 2


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
	; reset undefined processor state
	ldx $ff
	txs
	cld

	lda #%11111111
	sta IO_GPIO0
	; ; init ti UART
	; set fifo size and BRG on channel a, since it is shared
	; ; CRA - reset MR pointer
	lda #%10110000
	sta IO_UART2_CRA

	; MR0A
	lda #%00001001
	sta IO_UART2_MRA

	; MR1B
	lda #%00010011
	sta IO_UART2_MRB

	; MR2B
	lda #%00000111
	sta IO_UART2_MRB

	; CSRB
	lda #%11001100
	sta IO_UART2_CSRB

	lda #%00000101
	sta IO_UART2_CRB


	lda #%11111110
	sta IO_GPIO0
	jsr purge_channel2_input
	ldy #$00
@loop:
	lda filename, y
	iny
	jsr putc2
	bne @loop

	lda #%11111100
	sta IO_GPIO0
	jsr load_binary
	bcc @file_error
	jmp (RECEIVE_POS)

@file_error:
	lda #%10101010
	sta IO_GPIO0
@end_loop:
	nop
	jmp @end_loop


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
	lda #%11111000
	sta IO_GPIO0
	lda #%00000001
	sta BLINKENLIGHT
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
	bne @done

	ldx BLINKENLIGHT
	stx IO_GPIO0
	inx
	stx BLINKENLIGHT

	;
	; full page case: exactly 256 bytes
	;
@loop_full_page:
	jsr getc2	; recv next byte
	sta (IO_ADDR), y	;  and store to (IO_ADDR) + y
	iny
	bne @loop_full_page	; end on y wrap around

	dec RECEIVE_SIZE + 1	; dec remaining size 
	inc IO_ADDR + 1

	jmp @load_page_loop 
	
@done:
	sec
	rts



putc2:
	pha
@loop:
	lda IO_UART2_SRB
	and #%00000100
	beq @loop
	pla
	sta IO_UART2_FIFOB
	rts

getc2:
	; lda IO_UART_ISR2
	; and #%00000001
	lda IO_UART2_SRB
	and #%00000001
	beq getc2
	lda IO_UART2_FIFOB
shared_rts:
	rts
	

purge_channel2_input:
; purge any channel2 input buffer
	lda IO_UART2_SRB
	and #%00000001
	
	beq shared_rts
	lda IO_UART2_FIFOB
	jmp purge_channel2_input


irq:
	pha
	lda $fdfe
	ora $fdff
	beq @skip
	jmp ($fdfe)
@skip:
	pla
	rti
	

filename:
 	.byte "o.b", $00

