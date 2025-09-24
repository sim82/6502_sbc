
.INCLUDE "std.inc"
.INCLUDE "os.inc"

.macro println addr
	lda #<addr
	ldx #>addr
	jsr os_print_string
	jsr os_putnl
.endmacro

; .macro iprintln string
; .local @data
; .local @code
; jmp @code
; @data:
; 	.byte string, $00
; @code
; 	println @data
; .endmacro
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
	println init_message
	lda #OS_EVENT_RETURN_KEEP_RESIDENT
	jsr os_event_return
	rts

event_key:
	txa
	cmp #'t'
	beq test1
	cmp #'r'
	beq read1
	cmp #'i'
	beq init1
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
	lda #OS_EVENT_RETURN_KEEP_RESIDENT
	jsr os_event_return

	rts

exit_resident:
	println cmd_done_message
	lda #OS_EVENT_RETURN_KEEP_RESIDENT
	jsr os_event_return
	rts 

test1:
	; iprintln "test1"
	lda #0
	sta $fe20
	jmp exit_resident
read1:
	lda #0
	lda $fe27
	ldx #0
	jsr os_print_dec
	jsr os_putnl
	jmp exit_resident

init1:
	lda #'i'
	jsr os_putc
	jsr wait_ready
	lda #$a0
	sta $fe26
	lda #$ec
	sta $fe27
	jsr wait_ready
@wait_drq:
	lda $fe27
	and #%00001000
	bne @wait_drq

	ldy #$ff
@read_loop1:
	lda $fe20
	sta ARG0
	jsr os_dbg_byte
	dey
	bne @read_loop1
	
	jmp exit_resident
	

wait_ready:
	; lda $fe27
	; ldx #0
	; jsr os_print_dec
	; jsr os_putnl
	lda $fe27
	tay
	and #%10000000
	bne wait_ready
	println ready_message
	tya
	ldx #0
	
	jsr os_print_dec
	jsr os_putnl
	rts

.RODATA
init_message:
	.byte "Press q to exit...", $00

cmd_done_message:
	.byte "Cmd done...", $00

ready_message:
	.byte "Ready.", $00

