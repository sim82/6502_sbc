
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
	sta AX
	lda #10
	sta AY
	lda #0
	sta DIR
	sta INPUT
	lda #$01
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

	lda #$01
	jsr os_event_return
	rts

event_key:
	stx INPUT
	lda #OS_EVENT_RETURN_KEEP_RESIDENT
	jsr os_event_return
	rts 
	
event_timer:
	; check apple
	lda AX
	cmp APPLEX
	bne @no_apple
	lda AY
	cmp APPLEY
	bne @no_apple
	lda #$04
	clc
	adc GROW
	sta GROW

@no_apple:
	


	jsr set_color
	ldx APPLEX
	ldy APPLEY
	jsr goto_xy
	lda #'O'
	jsr os_putc

	; draw snake in a wonderfully spaghetti way
	; FIXME: the repeat crap is not working: queue increas is different in x / y direction!
	lda #$02
	sta REPEAT
@repeat:
	lda DIR
	sta DIR_OLD
	; update direction index: shift up old movement by 2 bits
	asl DIR
	asl DIR

	ldx INPUT
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
	dec REPEAT
	; end w
@no_w:
	cpx #'s'
	bne @no_s
	; start s: down
	lda DIR
	ora #%11
	sta DIR
	dec REPEAT
	; end s
@no_s:
	txa
	cmp #'q'
	beq @exit

	
	jsr check_collision
	bcc game_over
	
	jsr update_queue

	ldx AX
	ldy AY
	jsr gotov_xy

	
@skip:
	jsr os_putnl
	lda #OS_EVENT_RETURN_KEEP_RESIDENT
	jsr os_event_return
@exit:
	dec REPEAT
	bne @repeat_ind

	jsr update_grow
	rts
@repeat_ind:
	jmp @repeat

@not_allowed:
	; illegal movement, rollback DIR modification
	lda DIR_OLD
	sta DIR
	lda #$01
	jsr os_event_return
	rts

update_grow:

	lda GROW
	beq @no_grow
	dec GROW

@no_grow:
	rts

game_over:
	ldx #$20
	ldy #$10
	jsr goto_xy
	
	lda #<game_over_message
	ldx #>game_over_message
	jsr os_print_string
	jsr os_putnl
	lda #$00
	jsr os_event_return
	rts

check_collision:
	ldx QR
	
@loop:
	lda AX
	cmp QX, x
	bne @not_equal

	lda AY
	cmp QY, x
	bne @not_equal

	clc
	rts

@not_equal:
	inx
	cpx QW
	beq @exit
	jmp @loop


@exit:
	sec
	rts

update_queue:
	lda AX
	ldx QW
	sta QX, x
	lda AY
	sta QY, x

	lda GROW
	bne @grow

	ldx QR
	ldy QY, x
	lda QX, x
	cmp #$ff
	beq @skip_delete
	tax

	jsr goto_xy
	lda #' '
	jsr os_putc
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
	shl
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

	
set_color:
	jsr send_esc
	lda #'4'
	jsr os_putc
	lda #'1'
	jsr os_putc
	lda #'m'
	jsr os_putc
	rts


.RODATA
init_message:
	.byte "got init event", $00


input_message:
	.byte "got input event: ", $00

game_over_message:
	.byte "GAME OVER", $00

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
