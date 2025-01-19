
.INCLUDE "std.inc"

.IMPORT os_putc, os_getc, os_putnl, os_event_return, os_get_event
STR_PTR = $8b

.CODE
	jsr os_get_event
	cmp #$00
	beq @event_init

	cmp #$01
	beq @event_char
	
	rts


@event_init:
	lda #<message
	sta STR_PTR
	lda #>message
	sta STR_PTR+1
	jsr out_string

	lda #$01
	jsr os_event_return
	rts


@event_char:
	txa
	cmp #'q'
	beq @exit
	jsr os_putc
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
message:
	.byte "Hello, Relocator! I'm data...", $00
	; .asciiz "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqqrstuvwxyz"
; .byte "0123456789abcdef"
