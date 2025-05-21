
.INCLUDE "std.inc"
.INCLUDE "os.inc"

COUNT = $80
CHAR = $81

.CODE
	jsr os_get_event
	cmp #OS_EVENT_INIT
	beq dispatch_init

	cmp #OS_EVENT_KEY
	beq dispatch_key
	; beq event_char_boxtest

	cmp #OS_EVENT_TIMER
	beq dispatch_timer
	
	
	rts

dispatch_init:
	jmp event_init

dispatch_key:
	jmp event_key

dispatch_timer:
	jmp event_timer

	
event_init:
	jsr uartaux_init

@keyloop:
	jsr aux_getc
	bcc @keyloop
	sta IO_GPIO0
	; tay
	; ldx #00
	; jsr os_print_dec
	; jsr os_putnl
	; tya
	; jsr os_putc
	jsr aux_putc
	jmp @keyloop

	
; 	lda #%00000101
; 	sta IO_UARTAUX_CRA
; 	sta IO_UARTAUX_CRB
; 	jmp @keyloop
	lda #'!'
	sta CHAR
	lda #<init_message
	ldx #>init_message
	jsr os_print_string
	jsr os_putnl
	ldx #00
@loop:
	
	; lda $fe30
	; sta $fe00
	; ; lda #%11111111
	; stx $fe30
	; inx
	; jmp @loop
	lda #OS_EVENT_RETURN_KEEP_RESIDENT
	jsr os_event_return
	rts

event_key:
	txa
	cmp #'q'
	beq @exit_non_resident
@exit_resident:
	lda #OS_EVENT_RETURN_KEEP_RESIDENT
	jsr os_event_return
	rts 
@exit_non_resident:
	lda #OS_EVENT_RETURN_EXIT
	jsr os_event_return
	rts 

	
event_timer:
	lda COUNT
	sta $fe30
	inc COUNT
	lda CHAR
	jsr aux_putc
	inc CHAR
	lda CHAR
	cmp #$7f
	bne @no_reset
	lda #'!'
	sta CHAR
	lda #10
	jsr aux_putc
	lda #13
	jsr aux_putc

@no_reset:
	lda #OS_EVENT_RETURN_KEEP_RESIDENT
	jsr os_event_return

	rts


IO_UARTAUX_BASE   = IO_BASE + $40
IO_UARTAUX_MRA    = IO_UARTAUX_BASE + $0
IO_UARTAUX_CSRA   = IO_UARTAUX_BASE + $1
IO_UARTAUX_SRA    = IO_UARTAUX_BASE + $1
IO_UARTAUX_CRA    = IO_UARTAUX_BASE + $2
IO_UARTAUX_FIFOA  = IO_UARTAUX_BASE + $3
IO_UARTAUX_ACR    = IO_UARTAUX_BASE + $4
IO_UARTAUX_ISR    = IO_UARTAUX_BASE + $5
IO_UARTAUX_IMR    = IO_UARTAUX_BASE + $5
IO_UARTAUX_CTPU   = IO_UARTAUX_BASE + $6
IO_UARTAUX_CTPL   = IO_UARTAUX_BASE + $7
IO_UARTAUX_MRB    = IO_UARTAUX_BASE + $8
IO_UARTAUX_CSRB   = IO_UARTAUX_BASE + $9
IO_UARTAUX_SRB    = IO_UARTAUX_BASE + $9
IO_UARTAUX_CRB    = IO_UARTAUX_BASE + $a
IO_UARTAUX_FIFOB  = IO_UARTAUX_BASE + $b
IO_UARTAUX_SOPR   = IO_UARTAUX_BASE + $e
IO_UARTAUX_ROPR   = IO_UARTAUX_BASE + $f
IO_UARTAUX_CSTA   = IO_UARTAUX_BASE + $e
IO_UARTAUX_CSTO   = IO_UARTAUX_BASE + $f
uartaux_init:
	; init ti UART
	; CRA / CRB - reset tx / rx
	lda #%00100000
	sta IO_UARTAUX_CRA
	sta IO_UARTAUX_CRB
	lda #%00110000
	sta IO_UARTAUX_CRA
	sta IO_UARTAUX_CRB

	; CRA - reset MR pointer to 0
	lda #%10110000
	sta IO_UARTAUX_CRA

	; MR0A: select alternative BRG and fifo depth (channel a sets it globally)
	lda #%00001001
	sta IO_UARTAUX_MRA

	; CRB - reset MR pointer to 1
	lda #%00010000
	sta IO_UARTAUX_CRB

	; MR1A / MR1B
	lda #%00010011
	sta IO_UARTAUX_MRA
	sta IO_UARTAUX_MRB

	; MR2A / MR1B
 	lda #%00000111
	sta IO_UARTAUX_MRA
	sta IO_UARTAUX_MRB

	; CSRA / CSRB
	lda #%11001100
	sta IO_UARTAUX_CSRA
	sta IO_UARTAUX_CSRB

	; start command to A / B
	lda #%00000101
	sta IO_UARTAUX_CRA
	sta IO_UARTAUX_CRB
	rts

aux_putc:
; V_OUTP:
	pha
@loop:
	lda IO_UARTAUX_SRA
	and #%00000100
	beq @loop
	pla
	sta IO_UARTAUX_FIFOA
	rts

aux_getc:
; V_INPT:
@loop:
	; check transmit data register empty
	lda IO_UARTAUX_SRA
	and #%00000001
	beq @no_keypress
	lda IO_UARTAUX_FIFOA
        sec
	rts

@no_keypress:
        clc
	rts

.RODATA
init_message:
	.byte "Press q to exit...", $00



