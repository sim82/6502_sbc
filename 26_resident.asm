
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
	; draw snake in a wonderfully spaghetti way
	lda DIR
	sta DIR_OLD
	; update direction index: shift up old movement by 2 bits
	asl DIR
	asl DIR

	; put new movement into lowest 2 bits
	cpx #'a'
	bne @no_a
	; start a: left
	lda DIR
	ora #%00
	sta DIR
	; end a
@no_a:
	cpx #'d'
	bne @no_d
	; start d: right
	lda DIR
	ora #%01
	sta DIR
	; end d
@no_d:
	cpx #'w'
	bne @no_w
	; start w: up
	lda DIR
	ora #%10
	sta DIR
	; end w
@no_w:
	cpx #'s'
	bne @no_s
	; start s: down
	lda DIR
	ora #%11
	sta DIR
	; end s
@no_s:
	txa
	cmp #'q'
	beq @exit

	; now the lowest 4 bit of DIR contain an index into the various tables.
	;;;;
	; look up what to do next in main 'snake_table'
	lda DIR
	and #%1111
	tax
	lda snake_table, x
	cmp #$ff
	beq @not_allowed
	cmp #$fe
	beq @no_redraw

	; instruction to overdraw old coordinate with direction change character
	stx TMP_X
	ldx AX
	ldy AY
	jsr goto_xy

	lda TMP_X
	; multiply by 4 to correctly index into utf8 table
	asl
	asl
	tax
	; output utf8 codepoint
	ldy #3
@loop:
	lda snake_utf8, x
	jsr os_putc
	inx
	dey
	bne @loop

	ldx TMP_X
@no_redraw:
	; update coordinate
	lda snakex_table, x
	clc
	adc AX
	sta AX
	
	lda snakey_table, x
	clc
	adc AY
	sta AY
	
	ldx AX
	ldy AY
	jsr goto_xy

	; draw either horizontal or vertical line, based on lower 2 bit of DIR
	lda DIR
	and #%10
	bne @vert
	send_utf8 char_hline
	jmp @skip_vert
@vert:
	send_utf8 char_vline
	
@skip_vert:
	
@skip:
	jsr os_putnl
	lda #$01
	jsr os_event_return
@exit:
	rts

@not_allowed:
	; illegal movement, rollback DIR modification
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

;;;;; 
; snake tables.
; common to all tables: they are indexed by a 4bit index formed form the last movement (upper 2bits, aka. fr(om)) and 
; next movement (lower 2bits, aka. to).
; e.g. entry number 7 means what to do on a transition from right to u.

; table with 'instruction' what to do on the next step.
; values meaning:
;  $ff: not allowed. don't move, don't draw anything (e.g. on direct movement into opposite direction)
;  $fe: just draw the next character on the updated coordinate (e.g. left to left, up to up)
;  $00 - $03: overdraw last coordinate with utf character snake_utf8 table at index $00 - $03 (multiplied by 4),
;             then update coordinate and draw next character based on new movement direction
snake_table:
	; fr: l                   r                   u                   d
	; to: l    r    u    d    l    r    u    d    l    r    u    d    l    r    u    d    
	.byte $fe, $ff, $02, $00, $ff, $fe, $03, $01, $01, $00, $fe, $ff, $03, $02, $ff, $fe

; characters to overdraw old coordinate in case of (legal) direction change. indexed by value
; from snake_table (the values in the 'same direction' e.g. l-to-l, slots are just placeholders)
; NOTE: table contains utf8 characters, which are encoded as 3 bytes. space added after each character
;       to align character starts. make sure that this is assembled correctly.
snake_utf8:
	; fr:  l       r       u       d
	; to:  l r u d l r u d l r u d l r u d 
	.byte "═ ═ ╚ ╔ ═ ═ ╝ ╗ ╗ ╔ ║ ║ ╝ ╚ ║ ║ "

; x-coordinate offset
snakex_table:
	; fr: l                   r                   u                   d
	; to: l    r    u    d    l    r    u    d    l    r    u    d    l    r    u    d    
	.byte $ff, $00, $00, $00, $00, $01, $00, $00, $ff, $01, $00, $00, $ff, $01, $00, $00

; y-coordinate offset
snakey_table:
	; fr: l                   r                   u                   d
	; to: l    r    u    d    l    r    u    d    l    r    u    d    l    r    u    d    
	.byte $00, $00, $ff, $01, $00, $00, $ff, $01, $00, $00, $ff, $00, $00, $00, $00, $01
