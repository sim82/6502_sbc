
.INCLUDE "std.inc"
.INCLUDE "os.inc"

EXP = $80
CT_L = $81
CT_H = $82

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

	lda #00
	sta CT_L
	sta CT_H
	
	lda #<filename
	ldx #>filename
@cat_file:
	jsr os_fopen
	bcc @done
	
	lda #00
	sta EXP
@loop:
	jsr os_fgetc
	bcc @done
	cmp EXP

	beq @next

	tay

	lda #<error_message
	ldx #>error_message
	jsr os_print_string
	ldx #00
	jsr os_print_dec
	
	lda #' '
	jsr os_putc
	lda EXP
	jsr os_print_dec
	jsr os_putnl
	tya
	
@next:
	; sta IO_GPIO0
	inc
	sta EXP
	clc
	lda #1
	adc CT_L
	sta CT_L
	lda #0
	adc CT_H
	sta CT_H

	jmp @loop

@done:
	jsr os_print_fstat
	jsr os_putnl
	lda CT_L
	ldx CT_H
	jsr os_print_dec
	jsr os_putnl
	

	lda #OS_EVENT_RETURN_KEEP_RESIDENT
	jsr os_event_return

	rts

; read_raw_stress:


.RODATA
error_message:
	.byte "error: ", $00

filename:
	.byte "stress", $00

open_command:
	.byte "r stress", $00



