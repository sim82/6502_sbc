
; .AUTOIMPORT +
.INCLUDE "std.inc"

;change for ram build!
.SEGMENT "VECTORS"
	.WORD $FF00
	.WORD irq


ZP_PTR = $80

STATUS = ZP_PTR
IO_ADDR = STATUS + 1
DELAY0 = IO_ADDR + 2
DELAY1 = DELAY0 + 1
DELAY2 = DELAY1 + 1

; RECEIVE_POS = IO_ADDR + 2
; RECEIVE_SIZE = RECEIVE_POS + 2

; BLINKENLIGHT = RECEIVE_SIZE + 2
; LBA_LOW = BLINKENLIGHT + 1

START_VECTOR = $fdfc
IRQ_VECTOR = $fdfe

.CODE
	; reset undefined processor state
	ldx #$ff
	txs
	cld
	sei
;;;;;;;;;;;;;;;;;
; init io addr to $e000
	lda #00
	sta IO_ADDR
	sta STATUS
	lda #$10 ; hard coded $1000
	sta IO_ADDR + 1

;;;;;;;;;;;;;;;;;;
; init ti UART

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
;;;;;;;;;;;;;;;;;;;
; request .b 
	lda #'2'
	jsr putc2

	; ignore receive pos & size 
	jsr getc2
	cmp #$54
	bne load_hd
	jsr getc2
	cmp #$46
	bne load_hd

load_uart:
	lda #$1
	sta STATUS
	lda #'b'
	jsr putc2
	ldy #$00

@load_full_page:
	jsr getc2
	sta (IO_ADDR), y
	iny
	bne @load_full_page	; end on y wrap around
	inc IO_ADDR + 1
	lda IO_ADDR + 1
	; check if we reached the end of the 1000 - 2000 range
	cmp #$20
	beq done_load
	jmp load_uart

load_hd:
	lda #$2
	sta STATUS

	; inlined to reduce code size
@wait_ready_loop:
	lda $fe27
	; check BSY bit (bit 7)
	rol
	bcs @wait_ready_loop

	; lda #%11110000
	; sta IO_GPIO0
	; meaning of IO_ADDR vs RECEIVE_POS: 
	;  - IO_ADDR: in ZP, used for indirect addressing and modified during read
	;  - RECEIVE_POS: no need to be in ZP, used as entry point to program after read

	; hardcoded: load from lba $71 00 00 to $e000
	; lda #$71
	; sta LBA_LOW
	; X reg is exclusively used for LBA_LOW for the whole load process. NEVER USE X FOR ANY OTHER PURPOSE!
	ldx #$09

	; init ide registers
	lda #$00
	sta IO_IDE_LBA_MID
	sta IO_IDE_LBA_HIGH
	lda #$01
	sta IO_IDE_SIZE
	lda #$e0
	sta IO_IDE_DRIVE_HEAD

@load_page_loop:
	; issue read command to ide
	stx IO_IDE_LBA_LOW
	lda #$20
	sta IO_IDE_CMD
	; inlined wait drq
@wait_drq_loop:
	lda $fe27
	and #%00001000
	beq @wait_drq_loop

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
	lda IO_ADDR + 1
	; check if we reached the end of the 1000 - 2000 range
	cmp #$20
	beq @done
	; check if we are in the middle of 512 byte block
	ror
	bcs @loop_full_page

	; advance LBA_LOW	
	inx
	bne @load_page_loop ; always true, X never 0

@done:
done_load:
	; jmp (RECEIVE_POS)
	jmp $1000

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


getc2:
	; primitive timeout implementation:
	ldx #%11111000
	; init lower delay bytes with same value as highest byte to save one load instruction... (does not really matter and we are desparate for code size)
	stx DELAY0
	stx DELAY1
@loop:
	inc DELAY0
	bne @nocarry
	inc DELAY1
	bne @nocarry
	inx
	stx IO_GPIO0
	beq load_hd
@nocarry:
	lda IO_UART2_SRB
	; and #%00000001
	ror
	bcc @loop
	lda IO_UART2_FIFOB
shared_rts:
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
	


