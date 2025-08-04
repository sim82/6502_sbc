
.INCLUDE "std.inc"
.INCLUDE "os.inc"

.ZEROPAGE
x0: .res $1
y0: .res $1
x1: .res $1
y1: .res $1
xi: .res $1
yi: .res $1
xe: .res $1
d: .res $1
dx2: .res $1
dy2: .res $1
pi: .res $1
ii: .res $1
q13: .res $1
xoffs: .res $1
yoffs: .res $1

.BSS
pointsx:
	.res $100
pointsy:
	.res $100

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

	ldx #0
	stx pi
	lda #0
	
	lda #00
	sta ii
	
	lda #0
	ldx #0
	
	lda #10
	sta xoffs
	sta yoffs

	lda #0
	sta x1
	lda #32
	sta x0
	lda #0
	sta y0
	lda #32
	sta y1
	jsr render_square
	
; start direct timer
	lda #<direct_timer
	ldx #>direct_timer
	; lda #<direct_timer
	; ldx #>direct_timer
	ldy #3 ; set timer div to 6 * 16 = 96 ~ 100Hz (at 10kHz direct timer rate)
	jsr os_set_direct_timer


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
	lda #00
	ldx #00
	jsr os_set_direct_timer
	lda #OS_EVENT_RETURN_EXIT
	jsr os_event_return
	rts 

	
event_timer:
	; lda #'y'
	; jsr os_putc

; 	lda y1
; 	inc
; 	cmp #64
; 	bne @no_reset
; 	lda #0

; @no_reset:
; 	sta y1
; 	jsr bresenhamq0
	; inc x0
	; inc x1
	; inc y0
	; inc y1
	; ; jsr render_square
	; jsr setup_bresenham
	; jmp @skipy
	; lda #90
	inc xoffs
	; cmp xoffs
	; bcs @skipx
	; ldy #0
	; sty xoffs

@skipx:
	inc yoffs
	; cmp xoffs
	; bcs @skipx
	; ldy #0
	; sty xoffs
@skipy:
	lda #OS_EVENT_RETURN_KEEP_RESIDENT
	jsr os_event_return
	rts

direct_timer:
	; NOTE: make sure not to clobber X/Y registers! only A is auto restored by irq handler! (but don't waste time...)
	phx
	phy
	php

	; ldx pi
	; ; stx IO_GPIO20
	; ; stx IO_GPIO21

	; lda pointsx, x
	; sta IO_GPIO20
	; lda pointsy, x
	; sta IO_GPIO21
	; inx
	; stx pi

	jsr step_bresenham
	
; @ldloop:

	; jsr bresenhamq0

	plp
	ply
	plx
	rts
	
bresenhamq0:
	; calc D = 2 * (y1 - y0) - (x1-x0)
	; = (y1 - y0) * 2 - x1 + x0

	lda y1
	sec
	sbc y0
	asl
	sec
	sbc x1
	clc
	adc x0
	sta d
	; calc 2dx = 2 (x1 - x0)
	lda x1
	sec
	sbc x0
	asl
	sta dx2
	; calc 2dy = 2 (y1 - y0)
	lda y1
	sec
	sbc y0
	asl
	sta dy2

	ldy y0
	ldx x0
@loop:
	stx IO_GPIO20
	sty IO_GPIO21
	lda d
	bmi @no_y
	sec
	sbc dx2
	iny
@no_y:
	clc
	adc dy2
	sta d
	inx
	cpx x1
	bne @loop
	rts
	
setup_bresenham:
	; jmp @skip_print
	ldx #0
	lda x0
	jsr os_print_dec
	lda #' '
	jsr os_putc
	lda y0
	jsr os_print_dec
	lda #'-'
	jsr os_putc
	lda x1
	jsr os_print_dec
	lda #' '
	jsr os_putc
	lda y1
	jsr os_print_dec
	lda #' '
	jsr os_putc
@skip_print:
	; determine quadrant:
	; x0 <= x1 -> q0 or q1
	lda x0
	cmp x1
	bcc @q01
	beq @q01
@q23:
	lda y0
	cmp y1
	
	bcc @q3
	beq @q3
@q2:
	lda #'2'
	jsr os_putc
	lda #0
	sta q13
	; calc dx (inv), temporarily store in dx2
	lda x0
	sec
	sbc x1
	sta dx2
	
	; calc & store dy2 (inv)
	lda y0
	sec
	sbc y1
	asl
	sta dy2
	lda x1
	sta xi
	lda x0
	sta xe

	lda y1
	sta yi
	jmp @start

@q3:
	lda #'3'
	jsr os_putc
	lda #1
	sta q13
	; calc dx (inv), temporarily store in dx2
	lda x0
	sec
	sbc x1
	sta dx2
	
	; calc & store dy2
	lda y1
	sec
	sbc y0
	asl
	sta dy2
	lda x1
	sta xi
	lda x0
	sta xe

	lda y1
	sta yi
	jmp @start
@q01:
	; q0 or q1
	
	lda y0
	cmp y1
	bcc @q0
	beq @q0
@q1:
	lda #'1'
	jsr os_putc
	lda #1
	sta q13
	; calc dx, temporarily store in dx2
	lda x1
	sec
	sbc x0
	sta dx2
	
	; calc & store dy2 (inv)
	lda y0
	sec
	sbc y1
	asl
	sta dy2
	lda x0
	sta xi
	lda x1
	sta xe

	lda y0
	sta yi
	jmp @start

@q0:
	lda #'0'
	jsr os_putc
	
	lda #0
	sta q13
	; calc dx, temporarily store in dx2
	lda x1
	sec
	sbc x0
	sta dx2
	
	; calc & store dy2
	lda y1
	sec
	sbc y0
	asl
	sta dy2
	lda x0
	sta xi
	lda x1
	sta xe

	lda y0
	sta yi

@start:
	; subtract dx and store in d
	sec
	sbc dx2
	sta d
	; calc & store true dx2
	asl dx2

	rts

step_bresenham:
	lda q13
	bne step_bresenhamq13
	; fall through
step_bresenhamq02:
	ldx xi
	ldy yi
	txa
	clc
	adc xoffs
	sta IO_GPIO20

	tya
	clc
	adc yoffs
	sta IO_GPIO21

	lda d
	bmi @no_y
	sec
	sbc dx2
	iny
@no_y:
	clc
	adc dy2
	sta d
	inx
	cpx xe
	beq @reset
	stx xi
	sty yi
	jmp @end

@reset:
	jsr advance_line
	jsr setup_bresenham
@end:
	rts

step_bresenhamq13:
	ldx xi
	ldy yi
	txa
	clc
	adc xoffs
	sta IO_GPIO20

	tya
	clc
	adc yoffs
	sta IO_GPIO21

	lda d
	bmi @no_y
	sec
	sbc dx2
	dey
@no_y:
	clc
	adc dy2
	sta d
	inx
	cpx xe
	beq @reset
	stx xi
	sty yi
	jmp @end

@reset:
	jsr advance_line
	jsr setup_bresenham
@end:
	rts
	
advance_line:
	; inc pi
	lda pi
	and #$3
	tax
	lda linesx, x
	sta x0
	lda linesy, x
	sta y0
	inx
	txa
	and #$3
	sta pi
	tax
	lda linesx, x
	sta x1
	lda linesy, x
	sta y1
	rts

render_square:
	jsr render_xline
	lda y0
	pha
	lda y1
	sta y0
	
	jsr render_xline

	pla
	sta y0

	jsr render_yline
	
	lda x0
	pha
	lda x1
	sta x0
	
	jsr render_yline

	pla
	sta x0

	rts

render_xline:
	ldx ii
	ldy x0

@loop:
	lda y0
	sta pointsy, x
	tya
	sta pointsx, x
	inx
	iny
	cpy x1
	bne @loop

	stx ii
	rts
	
render_yline:
	ldx ii
	ldy y0

@loop:
	lda x0
	sta pointsx, x
	tya
	sta pointsy, x
	inx
	iny
	cpy y1
	bne @loop

	stx ii
	rts
	
misc_testing:

@outerloop:
	ldx #0
	ldy #0

	jmp @square
@xyloop:
	stx IO_GPIO20
	stx IO_GPIO21
	inx
	bne @xyloop
	jmp @outerloop
	
	; cli
@yloop:
	sty IO_GPIO21
@xloop:
	stx IO_GPIO20
	inx
	bne @xloop
	iny
	bne @yloop
	jmp @outerloop
	
@square:
	; ldy #255
	sta IO_GPIO20
	sta IO_GPIO21


@loopx1:
	sta IO_GPIO20
	inc
	bne @loopx1

@loopy1:
	sta IO_GPIO21
	inc
	bne @loopy1
	
@loopx2:
	sta IO_GPIO20
	inc
	bne @loopx2
	ldy #0
	sty IO_GPIO20
@loopy2:
	sta IO_GPIO21
	inc
	bne @loopy2
	jmp @outerloop

.RODATA
init_message:
	.byte "Press q to exit...", $00

linesx:
	.byte 16, 32, 16, 0
	
linesy:
	.byte 0, 16, 32, 16

