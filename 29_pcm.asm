
.INCLUDE "std.inc"
.INCLUDE "os.inc"

ZP = $80
COUNTER 	= ZP + $00
YL              = ZP + $01
YH              = ZP + $02
NOTE            = ZP + $03
DITHER_V	= ZP + $04
DITHER_I        = ZP + $05
DITHER_ENABLED  = ZP + $06
BASE_NOTE       = ZP + $07
ACC_L		= ZP + $08
ACC_H 		= ZP + $09
AMP		= ZP + $0a
AMP_CT          = ZP + $0b

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
	lda #00
	sta COUNTER
	sta YL
	sta YH
	sta DITHER_I
	sta DITHER_ENABLED
	lda #00
	sta NOTE
	lda #(60 - 24)
	sta BASE_NOTE
	lda #80
	sta AMP
	jsr calc_amp_ramp

	lda #<direct_timer
	ldx #>direct_timer
	ldy #3 ; set timer div to 6 * 16 = 96 ~ 100Hz (at 10kHz direct timer rate)
	jsr os_set_direct_timer
	lda #OS_EVENT_RETURN_KEEP_RESIDENT
	jsr os_event_return
	rts

event_key:
	txa
	cmp #'q'
	beq @exit_non_resident
	cmp #'p'
	bne @no_dither
	lda DITHER_ENABLED
	bne @disable
	lda #01
	jmp @end
@disable:
	lda #00
@end:
	sta DITHER_ENABLED
	

@no_dither:

	cmp #'n'
	bne @no_transpose_down

	lda BASE_NOTE
	sec
	sbc #12
	sta BASE_NOTE
@no_transpose_down:
	cmp #'m'
	bne @no_transpose_up
	lda BASE_NOTE
	clc
	adc #12
	sta BASE_NOTE

@no_transpose_up:
	cmp #','
	bne @no_amp_down
	lda AMP
	clc
	sbc #16
	sta AMP
	jsr calc_amp_ramp

@no_amp_down:
	cmp #'.'
	bne @no_amp_up
	lda #16
	clc
	adc AMP
	sta AMP
	jsr calc_amp_ramp

@no_amp_up:
	jsr keyboard_input

	
@not_inc:
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

	
direct_timer:
	phx
	phy
	ldx NOTE
	lda YL
	clc
	adc scale_l, x
	sta YL
	lda YH
	adc scale_h, x
	sta YH
	tax
	lda sin, x
	tax
	lda amp_ramp, x

; 	; lda #00
; 	ldx DITHER_ENABLED
; 	beq @no_dither
; 	jsr dither
; 	adc #00
; @no_dither:
	sta IO_GPIO0

	; jmp @exit_resident
	ply
	plx
	rts

event_timer:
	lda #'t'
	jsr os_putc
	; jmp @exit_resident
	; crappy envelope
	lda AMP
	beq @exit_resident

	; dec AMP_CT
	; bne @exit_resident
	; lda #$40
	; sta AMP_CT
	dec AMP
	jsr calc_amp_ramp

	
@exit_resident:
	; lda #00
	; sta IO_GPIO0
	lda #OS_EVENT_RETURN_KEEP_RESIDENT
	jsr os_event_return

	rts


keyboard_input:
	ldx #(KEYMAP_LEN - 1)
@loop:
	cmp map_key, x
	beq @found
	dex
	bpl @loop
	rts
@found:
	lda #$ff
	sta AMP
	lda #40
	sta AMP_CT 
	stx NOTE
	
	; lda #(36)
	lda BASE_NOTE
	sec
	sbc NOTE
	sta NOTE
	rts

dither:
	pha
	dec DITHER_I
	bmi @new_rand

@cont:
	ror DITHER_V
	pla
	rts
		

@new_rand:
	jsr os_rand
	sta DITHER_V
	lda #7
	sta DITHER_I
	jmp @cont

calc_amp_ramp:
	ldx #0
	stx ACC_L
	stx ACC_H
	
	ldy AMP

@loop:
	tya
	clc
	adc ACC_L
	sta ACC_L
	lda #00
	adc ACC_H
	sta ACC_H
	sta amp_ramp, x
	inx
	bne @loop
	rts
	
.BSS
amp_ramp:
	.RES $100

.RODATA
init_message:
	.byte "Press q to exit...", $00

sin:
	.byte    $80, $83, $86, $89, $8c, $8f, $92, $95, $98, $9b, $9e, $a2, $a5, $a7, $aa, $ad, $b0, $b3, $b6, $b9, $bc, $be, $c1, $c4, $c6, $c9, $cb, $ce, $d0, $d3, $d5, $d7, $da, $dc, $de, $e0, $e2, $e4, $e6, $e8, $e9, $eb, $ed, $ee, $f0, $f1, $f3, $f4, $f5, $f6, $f7, $f8, $f9, $fa, $fb, $fc, $fc, $fd, $fd, $fe, $fe, $fe, $fe, $fe, $fe, $fe, $fe, $fe, $fe, $fd, $fd, $fc, $fc, $fb, $fa, $fa, $f9, $f8, $f7, $f6, $f4, $f3, $f2, $f0, $ef, $ed, $ec, $ea, $e8, $e7, $e5, $e3, $e1, $df, $dd, $db, $d8, $d6, $d4, $d2, $cf, $cd, $ca, $c8, $c5, $c2, $c0, $bd, $ba, $b7, $b5, $b2, $af, $ac, $a9, $a6, $a3, $a0, $9d, $9a, $97, $94, $91, $8e, $8a, $87, $84, $81, $7e, $7b, $78, $75, $71, $6e, $6b, $68, $65, $62, $5f, $5c, $59, $56, $53, $50, $4d, $4a, $48, $45, $42, $3f, $3d, $3a, $37, $35, $32, $30, $2d, $2b, $29, $27, $24, $22, $20, $1e, $1c, $1a, $18, $17, $15, $13, $12, $10, $f, $d, $c, $b, $9, $8, $7, $6, $5, $5, $4, $3, $3, $2, $2, $1, $1, $1, $1, $1, $1, $1, $1, $1, $1, $2, $2, $3, $3, $4, $5, $6, $7, $8, $9, $a, $b, $c, $e, $f, $11, $12, $14, $16, $17, $19, $1b, $1d, $1f, $21, $23, $25, $28, $2a, $2c, $2f, $31, $34, $36, $39, $3b, $3e, $41, $43, $46, $49, $4c, $4f, $52, $55, $58, $5a, $5d, $61, $64, $67, $6a, $6d, $70, $73, $76, $79, $7c, $80
.INCLUDE "29_pcm_scale.inc"

KEYMAP_LEN = 13
map_key:
	.byte "awsedftgyhujk"
	
