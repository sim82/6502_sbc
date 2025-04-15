
.INCLUDE "std.inc"
.INCLUDE "os.inc"

ZP = $80
COUNTER 	= ZP + $00

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
	lda #<init_message
	ldx #>init_message
	jsr os_print_string
	jsr os_putnl
	lda #00
	sta COUNTER
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
	lda COUNTER
	inc
	sta IO_GPIO0
	sta COUNTER
	lda #OS_EVENT_RETURN_KEEP_RESIDENT
	jsr os_event_return

	rts


.RODATA
init_message:
	.byte "Press q to exit...", $00



