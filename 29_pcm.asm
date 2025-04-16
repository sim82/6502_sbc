
.INCLUDE "std.inc"
.INCLUDE "os.inc"

ZP = $80
COUNTER 	= ZP + $00

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
	lda #OS_EVENT_RETURN_EXIT
	jsr os_event_return
	rts 

	
event_timer:
	ldx COUNTER
	inx
	inx
	inx
	inx
	stx COUNTER

	; lda sin, x
	txa
	sta IO_GPIO0
	lda #OS_EVENT_RETURN_KEEP_RESIDENT
	jsr os_event_return

	rts


.RODATA
init_message:
	.byte "Press q to exit...", $00

sin:
	.byte    $80, $83, $86, $89, $8c, $8f, $92, $95, $98, $9b, $9e, $a2, $a5, $a7, $aa, $ad, $b0, $b3, $b6, $b9, $bc, $be, $c1, $c4, $c6, $c9, $cb, $ce, $d0, $d3, $d5, $d7, $da, $dc, $de, $e0, $e2, $e4, $e6, $e8, $e9, $eb, $ed, $ee, $f0, $f1, $f3, $f4, $f5, $f6, $f7, $f8, $f9, $fa, $fb, $fc, $fc, $fd, $fd, $fe, $fe, $fe, $fe, $fe, $fe, $fe, $fe, $fe, $fe, $fd, $fd, $fc, $fc, $fb, $fa, $fa, $f9, $f8, $f7, $f6, $f4, $f3, $f2, $f0, $ef, $ed, $ec, $ea, $e8, $e7, $e5, $e3, $e1, $df, $dd, $db, $d8, $d6, $d4, $d2, $cf, $cd, $ca, $c8, $c5, $c2, $c0, $bd, $ba, $b7, $b5, $b2, $af, $ac, $a9, $a6, $a3, $a0, $9d, $9a, $97, $94, $91, $8e, $8a, $87, $84, $81, $7e, $7b, $78, $75, $71, $6e, $6b, $68, $65, $62, $5f, $5c, $59, $56, $53, $50, $4d, $4a, $48, $45, $42, $3f, $3d, $3a, $37, $35, $32, $30, $2d, $2b, $29, $27, $24, $22, $20, $1e, $1c, $1a, $18, $17, $15, $13, $12, $10, $f, $d, $c, $b, $9, $8, $7, $6, $5, $5, $4, $3, $3, $2, $2, $1, $1, $1, $1, $1, $1, $1, $1, $1, $1, $2, $2, $3, $3, $4, $5, $6, $7, $8, $9, $a, $b, $c, $e, $f, $11, $12, $14, $16, $17, $19, $1b, $1d, $1f, $21, $23, $25, $28, $2a, $2c, $2f, $31, $34, $36, $39, $3b, $3e, $41, $43, $46, $49, $4c, $4f, $52, $55, $58, $5a, $5d, $61, $64, $67, $6a, $6d, $70, $73, $76, $79, $7c, $80


