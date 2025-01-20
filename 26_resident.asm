
.INCLUDE "std.inc"

.IMPORT os_putc, os_getc, os_putnl, os_event_return, os_get_event, os_print_string
STR_PTR = $8b

.CODE
	jsr os_get_event
	cmp #$00
	beq @event_init

	cmp #$01
	beq @event_char
	
	rts


@event_init:
	lda #<init_message
	ldx #>init_message
	jsr os_print_string
	jsr os_putnl

	lda #$01
	jsr os_event_return
	rts


@event_char:
	txa
	cmp #'q'
	beq @exit
	pha

	lda #<input_message
	ldx #>input_message
	jsr os_print_string

	pla
	jsr os_putc
	jsr os_putnl
	lda #$01
	jsr os_event_return

@exit:
	rts
	
out_string:
	ldy #$00
@loop:
	lda (STR_PTR), Y
	beq @end
	jsr os_putc
	iny
	jmp @loop
@end:
	jsr os_putnl
	rts

	
.RODATA
init_message:
	.byte "got init event", $00


input_message:
	.byte "got input event: ", $00

	; .asciiz "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqqrstuvwxyz"
; .byte "0123456789abcdef"
