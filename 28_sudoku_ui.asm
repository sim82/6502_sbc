.include "std.inc"
.include "os.inc"

.export ui_board, ui_init, ui_draw, ui_event_dispatch, print_space
.import test_input, solver_run

ZP = $90
CUR_Y = ZP + $00
CURSOR_X = ZP + $01
CURSOR_Y = ZP + $02

DRAW_X = 40
DRAW_Y = 10

.CODE
ui_init:
        jsr clear_screen
        ldx #80
@copy_loop:
        lda test_input, x
        sta ui_board, x
        dex
        bpl @copy_loop
        lda #00
        
        sta CURSOR_X
        sta CURSOR_Y
        rts

ui_draw:
        ldx #DRAW_X
        ldy #DRAW_Y
        sty CUR_Y
        inc CUR_Y
        jsr goto_xy
        ldy #9
        ldx #0
@draw_loop:
        lda ui_board, x
        jsr os_putc
        jsr print_space
        inx
        dey
        bne @no_newline
        ldy CUR_Y
        inc CUR_Y
        phx
        ldx #DRAW_X
        jsr goto_xy

        ldy #9
        plx

@no_newline:
        cpx #81
        bne @draw_loop

        lda CURSOR_X
        asl
        
        clc
        adc #DRAW_X
        tax
        lda #DRAW_Y
        clc 
        adc CURSOR_Y
        tay
        jsr goto_xy
        lda #'X'
        jsr os_putc

        jsr os_putnl
        rts

ui_event_dispatch:
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
        ; jsr start
        jsr ui_init
        jsr ui_draw
	lda #OS_EVENT_RETURN_KEEP_RESIDENT
	jsr os_event_return
        rts

event_key:
        cpx #'s'
        bne @no_solve
        jsr ui_to_stored
        jsr solver_run
        jmp @exit_resident

@no_solve:
        cpx #'k'
        bne @no_up
        lda CURSOR_Y
        beq @exit_resident
        dec CURSOR_Y
        jmp @exit_resident

@no_up:
        cpx #'j'
        bne @no_down
        lda CURSOR_Y
        cmp #8
        bcs @exit_resident
        inc CURSOR_Y
        jmp @exit_resident

@no_down:
        cpx #'h'
        bne @no_left
        lda CURSOR_X
        beq @exit_resident
        dec CURSOR_X
        jmp @exit_resident
@no_left:
        cpx #'l'
        bne @no_right
        lda CURSOR_X
        cmp #8
        bcs @exit_resident
        inc CURSOR_X
        jmp @exit_resident
@no_right:
        cpx #'c'
        bne @no_clear
        jsr calculate_cursor_pos
        lda #'.'
        sta ui_board, x
        jmp @exit_resident

@no_clear:
        cpx #'x'
        bne @no_clear_board

        ldx #80
        lda #'.'
@clear_loop:
        sta ui_board, x
        dex
        bpl @clear_loop
        jmp @exit_resident


@no_clear_board:
        cpx #'r'
        bne @no_restore
        jsr stored_to_ui

        jmp @exit_resident

@no_restore:


        cpx #'1'
        bcc @no_number
        cpx #':'
        bcs @no_number
        phx
        jsr calculate_cursor_pos
        pla
        sta ui_board, x
        jmp @exit_resident


@no_number:

@exit_resident:
        jsr ui_draw
	lda #OS_EVENT_RETURN_KEEP_RESIDENT
	jsr os_event_return
        rts

calculate_cursor_pos:
        ; cheapo version of 'CURSOR_X + CURSOR_Y * 9'
        lda CURSOR_X
        ldy CURSOR_Y
@craploop:
        beq @craploop_end
        clc
        adc #9
        dey
        jmp @craploop

@craploop_end:
        tax
        rts

event_timer:
        ; HACK: work around annoying '*' printed by dos...
        ldx #00
        ldy #00
        jsr goto_xy
	lda #OS_EVENT_RETURN_KEEP_RESIDENT
	jsr os_event_return
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
	inx
	txa
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
print_space:
        lda #' '
        jsr os_putc
        rts

ui_to_stored:
        ldx #80
@loop:
        lda ui_board, x
        sta stored_board, x
        dex
        bpl @loop
        rts
stored_to_ui:
        ldx #80
@loop:
        lda stored_board, x
        sta ui_board, x
        dex
        bpl @loop
        rts
        
.BSS
ui_board:
.RES 81

stored_board:
.RES 81

; pad
bss_pad:
.RES (256-81-81)
        
