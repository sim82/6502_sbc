
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
BIAS_TYPE	= ZP + $0c
WAVETABLE	= ZP + $0d
ADDRL		= ZP + $0e
ADDRH		= ZP + $0f
OVERFLOW	= ZP + $10
APPLY_VOLUME	= ZP + $11

IO		= IO_GPIO0

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
	sta BIAS_TYPE
	lda #01
	sta WAVETABLE
	sta APPLY_VOLUME
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

	lda #<sin
	ldx #>sin
	jsr copy_wavetable
	; jsr random_wavetable
	lda #OS_EVENT_RETURN_KEEP_RESIDENT
	jsr os_event_return
	rts

event_key:
	txa
	cmp #'q'
	bne @no_quit
	; exit non-resident
	lda #00
	ldx #00
	jsr os_set_direct_timer
	lda #OS_EVENT_RETURN_EXIT
	jsr os_event_return
	rts 

@no_quit:
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
	jmp @input_end
@no_transpose_down:
	cmp #'m'
	bne @no_transpose_up
	lda BASE_NOTE
	clc
	adc #12
	sta BASE_NOTE
	jmp @input_end

@no_transpose_up:
	cmp #','
	bne @no_amp_down
	lda AMP
	clc
	sbc #16
	sta AMP
	jsr calc_amp_ramp
	jmp @input_end

@no_amp_down:
	cmp #'.'
	bne @no_amp_up
	lda #16
	clc
	adc AMP
	sta AMP
	jsr calc_amp_ramp
	jmp @input_end

@no_amp_up:
	cmp #'b'
	bne @no_bias
	lda BIAS_TYPE
	; toggle between 0 / 1
	inc
	and #$01
	sta BIAS_TYPE
	jmp @input_end
@no_bias:
	cmp #'c'
	bne @no_wavetable
	lda WAVETABLE
	inc
	and #$01
	sta WAVETABLE
	jmp @input_end

@no_wavetable:
	cmp #'v'
	bne @no_volume
	lda APPLY_VOLUME
	inc
	and #$01
	sta APPLY_VOLUME
	jmp @input_end

@no_volume:
	cmp #'l'
	bne @no_load
	jsr load_wavetable

@no_load:
@input_end:
	jsr keyboard_input

	
@not_inc:
@exit_resident:
	lda #OS_EVENT_RETURN_KEEP_RESIDENT
	jsr os_event_return
	rts 


	
direct_timer:
	; NOTE: make sure not to clobber X/Y registers! only A is auto restored by irq handler! (but don't waste time...)
	phx
	phy
	ldx NOTE
	lda YL
	clc
	adc scale_l, x
	sta YL
	
	; crap dither
; 	lda DITHER_ENABLED
; 	beq @no_dither
; 	jsr os_rand
; 	clc
; 	adc YL
; @no_dither:
	; crap dither end

	; clc
	lda YH
	adc scale_h, x
	sta YH

	tax
	lda #00
	adc #00
	ora OVERFLOW
	sta OVERFLOW

	lda WAVETABLE
	beq @no_wavetable
	lda wavetable, x
	tax
@no_wavetable:
	ldy APPLY_VOLUME
	beq @no_volume
	lda amp_ramp, x
@no_volume:

; 	; lda #00
; 	ldx DITHER_ENABLED
; 	beq @no_dither
; 	jsr dither
; 	adc #00
; @no_dither:

	sta IO
	sta IO_GPIO10
	ply
	plx
	rts

event_timer:
	; lda #'t'
	; jsr os_putc
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
	ldy AMP

	lda BIAS_TYPE
	beq @midpoint_bias
	stx ACC_H
	jmp @loop
	
@midpoint_bias:
	; correctly bias output signal:
	; push up amp ramp by 0.5 + amp/2 (i.e. null-point is a t $80)
	tya ; AMP -> A
	lsr
	sta NUM1
	lda #$80
	sec
	sbc NUM1
	
	sta ACC_H


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

random_wavetable:
	ldx #$00
@loop:
	dex
	beq @end
	
	jsr os_rand
	
	sta wavetable, x
	jmp @loop
@end:
	rts

copy_wavetable:
	sta ADDRL
	stx ADDRH
	ldy #$00
@loop:
	lda (ADDRL), y
	; lda sin, y
	sta wavetable, y

	iny
	bne @loop

@end:
	rts

load_wavetable:
	lda #<filename
	ldx #>filename
	jsr os_fopen
	

	ldy #$00
@loop:
	jsr os_fgetc
	bcc @end
	; lda sin, y
	sta wavetable, y

	iny
	bne @loop
	lda #00
	sta OVERFLOW
	@wait_loop:
	lda OVERFLOW
	beq @wait_loop
	; bne @loop
	jmp @loop

@end:
	rts
	

.BSS
amp_ramp:
	.RES $100

wavetable:
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
	
filename:
	.byte "wavetable", $00
