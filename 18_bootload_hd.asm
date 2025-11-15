
; .AUTOIMPORT +
.INCLUDE "std.inc"

;change for ram build!
.SEGMENT "VECTORS"
	.WORD $FF00
	.WORD irq


ZP_PTR = $80


IO_ADDR = ZP_PTR + 2

RECEIVE_POS = IO_ADDR + 2
RECEIVE_SIZE = RECEIVE_POS + 2

BLINKENLIGHT = RECEIVE_SIZE + 2
LBA_LOW = BLINKENLIGHT + 1

START_VECTOR = $fdfc
IRQ_VECTOR = $fdfe

.CODE
	; reset undefined processor state
	ldx #$ff
	txs
	cld
	sei

	ldy #$00
	lda #$00
@delete_loop:
	sta $e100, y
	iny
	bne @delete_loop




load_binary:
	lda #%00001111
	sta IO_GPIO0
	; inlined to reduce code size
@wait_ready_loop:
	lda $fe27
	and #%10000000
	bne @wait_ready_loop
	lda #%11110000
	sta IO_GPIO0
	; meaning of IO_ADDR vs RECEIVE_POS: 
	;  - IO_ADDR: in ZP, used for indirect addressing and modified during read
	;  - RECEIVE_POS: no need to be in ZP, used as entry point to program after read

	; hardcoded: load from lba $71 00 00 to $e000
	lda #$71
	sta LBA_LOW

	; init ide registers
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

	lda #$00
	sta RECEIVE_SIZE
	lda #$1e
	sta RECEIVE_SIZE + 1

@load_page_loop:
	; issue read command to ide
	lda LBA_LOW
	sta IO_IDE_LBA_LOW
	lda #$20
	sta IO_IDE_CMD
	; inlined wait drq
@wait_drq_loop:
	lda $fe27
	and #%10001000
	cmp #%00001000
	bne @wait_drq_loop

	; this loop is running two times per (512 byte) io block:
	; 1) read the first 256 bytes to IO_ADDR
	; 2) then inc IO_ADDR high, and if lowest bit is set (i.e. it is the upper half of the current 
	;    512 byte io block) run the loop again for the next 256 bytes
	; 3) after the second run (when after IO_ADDR inc the low bit is 0), increase LBA_LOW address and start next io block
	;
	; Precondition: RECEIVE_POS must be 512 byte aligned!
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
	lda RECEIVE_SIZE + 1
	beq @done

	; check if we are currently in the middle of 512 byte block
	lda IO_ADDR + 1
	and #$1
	bne @loop_full_page
	
	inc LBA_LOW
	lda LBA_LOW
	cmp #$80
	bne @load_page_loop

@done:
	jmp (RECEIVE_POS)

; ==================
; wait_drq:
; 	lda $fe27
; 	and #%10001000
; 	cmp #%00001000
; 	bne wait_drq

; 	; println drq_message
; 	rts


; wait_ready:
; @loop:
; 	lda $fe27
; 	and #%10000000
; 	bne @loop
; 	rts

irq:
	pha
	lda IRQ_VECTOR
	ora IRQ_VECTOR + 1
	beq @skip
	; NOTE: special IRQ calling convention: irq handler must restore A before rti!
	;       Since we need to save A anyway and it is likely that A is used in the irq handler,
	;       we save one pha/pla pair.
	jmp (IRQ_VECTOR)
@skip:
	pla
	rti
	


