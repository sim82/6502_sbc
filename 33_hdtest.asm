
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

.RODATA
init_message:
	.byte "Press q to exit...", $00

cmd_done_message:
	.byte "Cmd done...", $00


