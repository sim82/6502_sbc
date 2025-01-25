
.INCLUDE "std.inc"

.IMPORT os_putc, os_getc, os_putnl, os_event_return, os_get_event, os_print_string, os_print_dec
AX = $80
AY = AX + 1
BX = AY + 1
BY = BX + 1
TMP_X = BY + 1
DIR = TMP_X + 1
DIR_OLD = DIR + 1
STR_PTR = DIR_OLD + 2


.macro send_utf8 ADDR
	.local @loop
	stx TMP_X
	ldx #0
@loop:
	lda ADDR, x
	jsr os_putc
	inx
	cpx #3
	bne @loop
	ldx TMP_X
.endmacro
.CODE
	jsr os_get_event
	cmp #$00
	beq event_init_draw
	; beq event_init_boxtest

	cmp #$01
	beq event_char_draw
	; beq event_char_boxtest
	
	rts


event_init_boxtest:
	jsr clear_screen
	lda #15
	jsr os_putc
	lda #'#'
	jsr os_putc
	lda #20
	sta AX
	lda #10
	sta AY
	lda #40
	sta BX
	lda #20
	sta BY
	jsr draw_box

	lda #$01
	jsr os_event_return
	rts


event_char_boxtest:
	jsr clear_screen
	cpx #'d'
	bne @no_d
	inc AX
	inc BX
@no_d:
	cpx #'a'
	bne @no_a
	dec AX
	dec BX
@no_a:
	cpx #'w'
	bne @no_w
	dec AY
	dec BY
@no_w:
	cpx #'s'
	bne @no_s
	inc AY
	inc BY
@no_s:
	txa
	cmp #'q'
	beq @exit
	pha
	jsr draw_box

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
	
event_init_draw:
	jsr clear_screen
	lda #20
	sta AX
	lda #10
	sta AY
	lda #0
	sta DIR
	lda #$01
	jsr os_event_return
	rts

event_char_draw:
	lda DIR
	sta DIR_OLD
	asl DIR
	asl DIR
	cpx #'a'
	bne @no_a
	; start d
	lda DIR
	ora #%00
	sta DIR
	; end d
@no_a:
	cpx #'d'
	bne @no_d
	; start a
	lda DIR
	ora #%01
	sta DIR
	; end a
@no_d:
	cpx #'w'
	bne @no_w
	; start w
	lda DIR
	ora #%10
	sta DIR
	; end w
@no_w:
	cpx #'s'
	bne @no_s
	; start s
	lda DIR
	ora #%11
	sta DIR
	; end s
@no_s:
	txa
	cmp #'q'
	beq @exit


	lda DIR
	and #%1111
	tax
	lda snake_table, x
	cmp #'x'
	beq @not_allowed
	lda snakex_table, x
	clc
	adc AX
	sta AX
	
	lda snakey_table, x
	clc
	adc AY
	sta AY
	
	lda snake_table, x
	pha
	ldx AX
	ldy AY
	jsr goto_xy
	pla
	jsr os_putc
	; lda #'o'
@skip:
	jsr os_putnl
	lda #$01
	jsr os_event_return
@exit:
	rts
@not_allowed:
	lda DIR_OLD
	sta DIR
	lda #$01
	jsr os_event_return
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

clear_screen:
	jsr send_esc
	lda #'2'
	jsr os_putc
	lda #'J'
	jsr os_putc
	rts
	
goto_xy:
	jsr send_esc
	txa
	pha
	
	ldx #$00

	tya
	jsr os_print_dec
	lda #';'
	jsr os_putc
	pla
	jsr os_print_dec
	lda #'H'
	jsr os_putc
	rts
	

send_esc:
	; lda #$9b
	; jsr os_putc
	lda #$1b
	jsr os_putc
	lda #'['
	jsr os_putc
	rts

	
draw_xline:
	ldx AX
	inx
@loop:
	cpx BX
	beq @end
	send_utf8 char_hline
	inx
	jmp @loop
@end:
	rts

draw_yline:
	ldy AY
	iny
@loop:
	cpy BY
	beq @end
	send_utf8 char_vline
	lda #8
	jsr os_putc
	lda #10
	jsr os_putc
	iny
	jmp @loop
@end:
	rts

draw_box:
	ldx AX
	ldy AY
	jsr goto_xy
	send_utf8 char_corner_lu
	inx
	jsr draw_xline
	send_utf8 char_corner_ss
	ldx AX
	ldy AY
	iny
	jsr goto_xy
	jsr draw_yline
	ldx BX
	ldy AY
	iny
	jsr goto_xy
	jsr draw_yline
	ldx AX
	ldy BY
	jsr goto_xy
	send_utf8 char_corner_ll
	inx
	jsr draw_xline
	send_utf8 char_corner_rl
	rts



.RODATA
init_message:
	.byte "got init event", $00


input_message:
	.byte "got input event: ", $00

char_corner_lu:
	.byte "╔"
char_corner_ss:
	.byte "╗"
char_corner_ll:
	.byte "╚"
char_corner_rl:
	.byte "╝"

char_hline:
	.byte "═"
	; .byte "║"
char_vline:
	.byte "║"
	; .byte "═"

snake_table:
	.byte "hx14xh2134vx12xv"

snakex_table:
	.byte $ff, $00, $ff, $ff, $00, $01, $01, $01, $00, $00, $00, $00, $00, $00, $00, $00

snakey_table:
	.byte $00, $00, $00, $00, $00, $00, $00, $00, $ff, $00, $ff, $ff, $01, $01, $00, $01
	; .asciiz "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqqrstuvwxyz"
; .byte "0123456789abcdef"
