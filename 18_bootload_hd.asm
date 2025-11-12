
.AUTOIMPORT +
.INCLUDE "std.inc"
.SEGMENT "VECTORS"
; change for ram build!
	; .WORD $FF00
	; .WORD irq
	; .WORD $3000




ZP_PTR = $80


IO_ADDR = ZP_PTR + 2

RECEIVE_POS = IO_ADDR + 2
RECEIVE_SIZE = RECEIVE_POS + 2

BLINKENLIGHT = RECEIVE_SIZE + 2
LBA_LOW = BLINKENLIGHT + 1

START_VECTOR = $fdfc
IRQ_VECTOR = $fdfe

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
	sei

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

	; hardcoded: load from lba $71 00 00 to $e000
	lda #$71
	sta LBA_LOW

	; init ide registers

	sta IO_IDE_LBA_LOW
	lda #$00
	sta IO_IDE_LBA_MID
	sta IO_IDE_LBA_HIGH
	lda #$01
	sta IO_IDE_SIZE
	lda #$e0
	sta IO_IDE_DRIVE_HEAD


	lda #$00 ; hard coded $e000
	sta RECEIVE_POS
	sta IO_ADDR
	lda #$e0 ; hard coded $e000
	sta RECEIVE_POS + 1	
	sta IO_ADDR + 1
	lda #%11111000
	sta IO_GPIO0

	; check for file error: target addr high $ff (this is always rom)
	; low byte check not necessary
	cmp #$FF
	bne @no_error
	; fell through -> error
	clc
	rts

@no_error:
	lda #$00
	sta RECEIVE_SIZE
	; jsr print_hex8
	lda #$1e
	sta RECEIVE_SIZE + 1
	beq @done

	; no space for size check...
	;
	; outer loop over all received pages
	; pages are loaded into IO_BUFFER one by one
	;
@load_page_loop:

	; issue read command to ide
	lda LBA_LOW
	sta IO_GPIO0
	sta IO_IDE_LBA_LOW
	lda #$20
	sta IO_IDE_CMD
	jsr wait_drq

	ldy #$00
@loop_full_page:
	lda IO_IDE_DATA_LOW
	sta (IO_ADDR), y
	iny
	lda IO_IDE_DATA_HIGH
	sta (IO_ADDR), y
	iny
	bne @loop_full_page	; end on y wrap around
	inc IO_ADDR + 1
	dec RECEIVE_SIZE + 1	
	beq @done
	ldy #$00
@loop_full_page2:
	lda IO_IDE_DATA_LOW
	sta (IO_ADDR), y
	iny
	lda IO_IDE_DATA_HIGH
	sta (IO_ADDR), y
	iny
	bne @loop_full_page2	; end on y wrap around
	inc IO_ADDR + 1
	dec RECEIVE_SIZE + 1	
	beq @done

	inc LBA_LOW
	cmp #$80
	bne @load_page_loop
@done:
	
	sec
	rts

; ==================
wait_drq:
	lda $fe27
	and #%10001000
	cmp #%00001000
	bne wait_drq

	; println drq_message
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
	lda IRQ_VECTOR
	ora IRQ_VECTOR + 1
	beq @skip
	jmp (IRQ_VECTOR)
@skip:
	pla
	rti
	

filename:
 	.byte "o.b", $00

