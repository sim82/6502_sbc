
.INCLUDE "std.inc"
.INCLUDE "os.inc"

; .IMPORT os_putc, os_getc, os_putnl, os_event_return, os_get_event, os_print_string, os_print_dec
AX = $80
AY = AX + 1
BX = AY + 1
BY = BX + 1
TMP_X = BY + 1
DIR = TMP_X + 1
DIR_OLD = DIR + 1
STR_PTR = DIR_OLD + 2
INPUT = STR_PTR + 2
REPEAT = INPUT + 1

QW = REPEAT+1
QR = QW + 1
GROW = QR + 1

APPLEX = GROW + 1
APPLEY = APPLEX + 1

HEADX = APPLEY + 1
HEADY = HEADX + 1

UP = $1
DOWN = $2
LEFT = $3
RIGHT = $4

BORDER_UP = 0
BORDER_LEFT = 0
BORDER_DOWN = 25
BORDER_RIGHT = 40

.BSS
QX:
	.RES $100

QY:
	.RES $100

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
	jsr clear_screen
	lda #20
	sta HEADX
	lda #10
	sta HEADY
	lda #1
	sta DIR
	sta DIR_OLD
	; init queues
	lda #$ff
	ldy #$00
@loop:
	sta QX, y
	sta QY, y
	iny
	bne @loop
	lda #$0
	sta QW
	lda #$f0
	sta QR

	lda #$00
	sta GROW

	lda #$12
	sta APPLEX
	lda #$8
	sta APPLEY

	lda #BORDER_LEFT
	sta AX
	lda #BORDER_UP
	sta AY
	lda #BORDER_DOWN
	sta BY
	lda #BORDER_RIGHT
	sta BX
	lda #'1'
	jsr set_color
	jsr draw_box
	lda #'9'
	jsr set_color
	

	lda #$01
	jsr os_event_return
	rts

event_key:
	lda DIR
	sta DIR_OLD
	cpx #'a'
	bne @no_a
	lda #LEFT
	sta DIR
	jmp @exit_resident
@no_a:
	cpx #'d'
	bne @no_d
	lda #RIGHT
	sta DIR
	jmp @exit_resident
@no_d:
	cpx #'w'
	bne @no_w
	lda #UP
	sta DIR
	jmp @exit_resident
@no_w:
	cpx #'s'
	bne @no_s
	lda #DOWN
	sta DIR
	jmp @exit_resident
@no_s:
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
	jsr print_debug_pos
	; check apple
	lda HEADX
	cmp APPLEX
	bne @no_apple
	lda HEADY
	cmp APPLEY
	bne @no_apple
	lda #$04
	clc
	adc GROW
	sta GROW

	jsr new_apple_position


@no_apple:
	
	ldx APPLEX
	ldy APPLEY
	jsr draw_apple

	ldx DIR
	lda dir_forbidden_table, x
	cmp DIR_OLD
	bne @allowed
	
	; illegal movement, rollback DIR modification
	lda DIR_OLD
	sta DIR
@allowed:
	
	clc
	ldx DIR
	lda dirx_table, x
	adc HEADX
	sta HEADX
	
	clc
	lda diry_table, x
	adc HEADY
	sta HEADY
	
	jsr check_collision
	bcc game_over
	
	jsr update_queue

	ldx HEADX
	ldy HEADY
	jsr draw_snake
	
	ldx #0
	ldy #20
	jsr gotov_xy
	; jsr os_putnl
	jsr update_grow
	lda #OS_EVENT_RETURN_KEEP_RESIDENT
	jsr os_event_return

	rts


update_grow:

	lda GROW
	beq @no_grow
	dec GROW

@no_grow:
	rts

draw_apple:
	jsr gotov_xy
	lda #'2'
	jsr set_color
	jsr draw_tile
	lda #'9'
	jsr set_color
	rts

draw_snake:
	jsr gotov_xy
	lda #'1'
	jsr set_color
	jsr draw_tile
	lda #'9'
	jsr set_color
	rts
draw_empty:
	jsr gotov_xy
	lda #'9'
	jsr set_color
	jsr draw_tile
	rts
game_over:
	ldx #$10
	ldy #$10
	jsr gotov_xy
	
	lda #<game_over_message
	ldx #>game_over_message
	jsr os_print_string
	jsr os_putnl
	lda #$00
	jsr os_event_return
	rts

check_collision:
	lda HEADX
	sta BX
	lda HEADY
	sta BY
	jmp check_snake_collision

check_snake_collision:
	; x,y in BX,BY
	; 1. check againt borders
	lda BX
	cmp #BORDER_LEFT
	beq @exit_bad
	cmp #BORDER_RIGHT
	beq @exit_bad
	lda BY
	cmp #BORDER_UP
	beq @exit_bad
	cmp #BORDER_DOWN
	beq @exit_bad

	; 2. check against snake queue
	ldx QR
@loop:
	lda BX
	cmp QX, x
	bne @not_equal

	lda BY
	cmp QY, x
	bne @not_equal

	jmp @exit_bad

@not_equal:
	inx
	cpx QW
	beq @exit
	jmp @loop

@exit:
	sec
	rts
@exit_bad:
	clc
	rts

draw_tile:
	lda #' '
	jsr os_putc
	jsr os_putc
	rts

update_queue:
	lda HEADX
	ldx QW
	sta QX, x
	lda HEADY
	sta QY, x

	lda GROW
	bne @grow

	ldx QR
	ldy QY, x
	lda QX, x
	cmp #$ff
	beq @skip_delete
	tax

	jsr draw_empty
@skip_delete:
	inc QR
@grow:
	inc QW

	rts


clear_screen:
	jsr send_esc
	lda #'2'
	jsr os_putc
	lda #'J'
	jsr os_putc
	rts
	
gotov_xy:
	jsr send_esc
	inx
	txa
	asl
	pha
	
	ldx #$00

	iny
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

	
set_color:
	pha
	jsr send_esc
	lda #'4'
	jsr os_putc
	pla
	jsr os_putc
	lda #'m'
	jsr os_putc
	rts

	ldx QR
	


new_apple_position:
	; kind of crappy modulo replacement
	jsr os_rand
	and #63
	cmp #BORDER_LEFT
	bcs @left_ok
	clc
	adc #3
@left_ok:
	cmp #BORDER_RIGHT	
	bcc @right_ok
	clc
	sbc #3
	jmp @left_ok

@right_ok:

	sta APPLEX
	sta BX
	jsr os_rand
	inc
	and #31

	cmp #BORDER_UP
	bcs @up_ok
	clc
	adc #3
@up_ok:
	cmp #BORDER_DOWN
	bcc @down_ok
	clc 
	sbc #3
	jmp @up_ok
@down_ok:

	sta APPLEY
	sta BY

	jsr check_snake_collision
	bcc new_apple_position
	
	rts

print_debug_pos:
	ldx #10
	ldy #30
	jsr gotov_xy
	lda HEADX
	ldx #0
	jsr os_print_dec
	lda #','
	jsr os_putc

	lda HEADY
	ldx #0
	jsr os_print_dec
	lda #' '
	jsr os_putc
	jsr os_putc
	
	
	ldx #10
	ldy #31
	jsr gotov_xy
	lda APPLEX
	ldx #0
	jsr os_print_dec
	lda #','
	jsr os_putc

	lda APPLEY
	ldx #0
	jsr os_print_dec
	lda #' '
	jsr os_putc
	jsr os_putc
	rts
draw_box:
	ldx AX
	ldy AY
	jsr gotov_xy
	jsr draw_xline
	ldx AX
	ldy AY
	jsr gotov_xy
	jsr draw_yline
	ldx BX
	ldy AY
	jsr gotov_xy
	jsr draw_yline
	ldx AX
	ldy BY
	jsr gotov_xy
	jsr draw_xline
	rts

draw_xline:
	ldx AX
@loop:
	cpx BX
	beq @end
	jsr draw_tile
	inx
	jmp @loop
@end:
	rts

draw_yline:
	ldy AY
@loop:
	cpy BY
	beq @end
	jsr draw_tile
	lda #8
	jsr os_putc
	jsr os_putc
	lda #10
	jsr os_putc
	iny
	jmp @loop
@end:
	rts
.RODATA
init_message:
	.byte "got init event", $00


input_message:
	.byte "got input event: ", $00

game_over_message:
	.byte "GAME OVER", $00



dirx_table:
	.byte $00, $00, $00, $ff, $01

diry_table:
	.byte $00, $ff, $01, $00, $00

dir_forbidden_table:
	.byte $00, DOWN, UP, RIGHT, LEFT
