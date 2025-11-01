
.INCLUDE "std.inc"
.INCLUDE "os.inc"

.ZEROPAGE
last_stat: .res $1
loop_count: .res $1
lba_low: .res $1
lba_mid: .res $1
lba_high: .res $1
next_pattern: .res $1
auto_inc: .res $1



.BSS
input_buf: .res $100
input_buf_h: .res $100

.macro println addr
	lda #<addr
	ldx #>addr
	jsr os_print_string
	jsr os_putnl
.endmacro

; .macro iprintln string
; .local @data
; .local @code
; jmp @code
; @data:
; 	.byte string, $00
; @code
; 	println @data
; .endmacro
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
	lda #$00
	sta lba_low
	sta lba_mid
	sta lba_high
	sta auto_inc
	println init_message
	lda #OS_EVENT_RETURN_KEEP_RESIDENT
	jsr os_event_return
	rts

event_key:
	txa
	cmp #'d'
	beq tdump_buf
	cmp #'x'
	beq tprint_status
	cmp #'['
	beq tdec_high
	cmp #']'
	beq tinc_high
	cmp #';'
	beq tdec_mid
	cmp #$27 ; char '
	beq tinc_mid
	cmp #','
	beq tdec_low
	cmp #'.'
	beq tinc_low
	cmp #'r'
	beq tread
	cmp #'w'
	beq twrite
	cmp #'p'
	beq tpattern
	cmp #'a'
	beq ttoggle_autoinc
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

tdump_buf:
	jmp cmd_dump_buf
tprint_status:
	jmp cmd_print_status
tdec_high:
	dec lba_high
	jmp exit_resident
tinc_high:
	inc lba_high
	jmp exit_resident
tdec_mid:
	dec lba_mid
	jmp exit_resident
tinc_mid:
	inc lba_mid
	jmp exit_resident
tdec_low:
	dec lba_low
	jmp exit_resident
tinc_low:
	inc lba_low
	jmp exit_resident
tread:
	jmp cmd_read
twrite:
	jmp cmd_write
tpattern:
	jmp cmd_pattern
ttoggle_autoinc:
	jmp cmd_toggle_autoinc


event_timer:
	lda #OS_EVENT_RETURN_KEEP_RESIDENT
	jsr os_event_return

	rts

exit_resident:
	jsr print_status
	println cmd_done_message
	lda #OS_EVENT_RETURN_KEEP_RESIDENT
	jsr os_event_return
	rts 

; =======================================
; commands
; ======================================

cmd_write:
	jsr set_size
	jsr set_low
	jsr set_mid
	jsr set_high
	jsr send_write
	jsr write_block
	jmp exit_resident

cmd_read:
	jsr set_size
	jsr set_low
	jsr set_mid
	jsr set_high
	jsr send_read
	jsr read_block
	jsr dump_buf
	jsr apply_autoinc
	jmp exit_resident

cmd_print_status:
	jmp exit_resident

cmd_dump_buf:
	jsr dump_buf
	jmp exit_resident
	
cmd_pattern:
	jsr gen_variable_pattern
	jmp exit_resident
cmd_toggle_autoinc:
	lda #$1
	eor auto_inc
	sta auto_inc
	jmp exit_resident


; ==================
identify:
	lda #$ec
	sta $fe27
	jmp exit_resident
	
	
; ==================
benign_write:
	lda #$00
	sta $fe21
	jmp exit_resident

; ==================
; read_all:
; 	lda #00
; 	sta lba_low
; 	sta lba_mid
; 	sta lba_high

; @loop:
; 	; jsr wait_ready
; 	; bcc @error
; 	; lda #$01
; 	; sta $fe22
; 	; lda lba_low
; 	; sta $fe23
; 	; lda lba_mid
; 	; sta $fe24
; 	; lda lba_high
; 	; sta $fe25

; 	; lda #$e0
; 	; sta $fe26
; 	; lda #$20
; 	; sta $fe27

; 	; jsr wait_ready
; 	; bcc @error
; 	; jsr read_block
; 	jsr setsize
; 	jsr setlow
; 	jsr setmid
; 	jsr sethigh
; 	jsr readcmd
; 	jsr read_block
; 	jsr dump_buf

; 	clc
; 	lda #1
; 	adc lba_low
; 	sta lba_low
; 	lda #0
; 	adc lba_mid
; 	sta lba_mid
; 	lda #0
; 	adc lba_high
; 	sta lba_high
; 	jmp @loop
	
; @error:
; 	jmp exit_resident

	
	
; =======================================
; utility functions
; ======================================
; ==================
print_status:
	jsr dump_prog_state
	jsr dump_registers
	lda $fe27
	sta ARG0
	jsr os_dbg_byte
	jsr os_putnl
	rts

; ==================
dump_prog_state:
	lda auto_inc
	sta ARG0
	jsr os_dbg_byte
	jsr os_putnl

	lda lba_low
	sta ARG0
	jsr os_dbg_byte
	
	lda lba_mid
	sta ARG0
	jsr os_dbg_byte

	lda lba_high
	sta ARG0
	jsr os_dbg_byte
	jsr os_putnl
	rts

dump_registers:
	lda $fe22
	sta ARG0
	jsr os_dbg_byte
	
	lda $fe23
	sta ARG0
	jsr os_dbg_byte
	lda $fe24
	sta ARG0
	jsr os_dbg_byte
	lda $fe25
	sta ARG0
	jsr os_dbg_byte
	lda $fe26
	sta ARG0
	jsr os_dbg_byte
	jsr os_putnl
	rts
	
; ==================
set_size:
	lda #$01
	sta $fe22
	; jsr wait_ready
	rts
set_low:
	lda lba_low
	; sta ARG0
	; jsr os_dbg_byte
	sta $fe23
	; jsr wait_ready
	rts
	
set_mid:
	lda lba_mid
	sta $fe24
	; jsr wait_ready
	rts
	
set_high:
	lda lba_high
	sta $fe25
	; jsr wait_ready
	rts
	
send_read:
	lda #$e0
	sta $fe26
	lda #$20
	sta $fe27
	; jsr wait_ready
	jsr wait_drq
	rts
		
send_write:
	lda #$e0
	sta $fe26
	lda #$30
	sta $fe27
	; jsr wait_ready
	jsr wait_drq
	rts
	
check_rdy:
	lda #0
	sta last_stat
@loop:
	lda $fe27
	cmp last_stat
	beq @loop
	sta last_stat
	sta ARG0
	jsr os_dbg_byte
	jmp @loop

; ==================
gen_pattern:
	
	ldx #$00
@loop:
	txa
	and #%00001111
	ora #%01100000
	sta input_buf, x
	txa 
	and #%00001111
	ora #%00110000
	sta input_buf_h, x
	inx
	bne @loop

	rts

	
gen_variable_pattern:
	ldx #$00
	
@loop:
	lda next_pattern
	and #%00001111
	ora #%01100000
	sta input_buf, x
	lda next_pattern
	and #%00001111
	ora #%00110000
	sta input_buf_h, x
	inx
	bne @loop


	inc next_pattern
	rts

; ==================
apply_autoinc:
	lda auto_inc
	clc
	adc lba_low
	sta lba_low
	lda #0
	adc lba_mid
	sta lba_mid
	lda #0
	adc lba_high
	sta lba_high
	adc lba_low
	
	rts

; ==================
wait_ready:
	lda $fe27
	tay
	and #%00000001
	bne @error
	tya
	and #%10000000
	bne wait_ready
	println ready_message
	sty ARG0
	jmp @end
@error:
	sty ARG0
	println error_message
	jsr os_dbg_byte
	lda #' '
	jsr os_putc
	lda $fe21
	sta ARG0
@end:
	jsr os_dbg_byte
	jsr os_putnl
	sec
	rts

wait_ready_int:
	lda $fe27
	and #%00000001
	bne @error
	sec
@loop:
	lda $fe27
	and #%10000000
	bne @loop
	rts
@error:
	clc
	rts

; ==================
wait_drq:
	lda $fe27
	and #%10001000
	cmp #%00001000
	bne wait_drq

	; println drq_message
	rts

; ==================
check_drq:
	lda $fe27
	; shift drq bit into C
	asl
	asl
	asl
	asl
	asl
	; println drq_message
	rts

; ==================
check_error:
	lda $fe27
	and #%00000001
	beq @noerror

	lda $fe27
	sta ARG0
	println error_message
	jsr os_dbg_byte
	lda $fe21
	sta ARG0
	jsr os_dbg_byte
	jsr os_putnl
@loop:
	jmp @loop
@noerror:
	rts

; ==================
read_block:
	ldx #$0
@loop:
	jsr check_error
	jsr wait_ready_int
	jsr check_drq
	bcc @end
	lda $fe20
	sta input_buf, x
	lda $fe28
	sta input_buf_h, x
	inx
	jmp @loop
@end:

	stx ARG0
	jsr os_dbg_byte
	jsr os_putnl
	rts

; ==================
write_block:
	ldx #$0
@loop:
	jsr check_error
	jsr wait_ready_int
	; stx ARG0
	; jsr os_dbg_byte
	; jsr os_putnl
	jsr check_drq
	bcc @end
	lda input_buf_h, x
	sta $fe28
	lda input_buf, x
	sta $fe20
	inx
	jmp @loop
@end:
	stx ARG0
	jsr os_dbg_byte
	jsr os_putnl
	rts

; ==================
print_alphanum:
	; sta ARG0
	; jsr os_dbg_byte
	cmp #'0'
	bcc @dontprint
	cmp #$7f
	bcc @exit

	
@dontprint:
	lda #'.'

@exit:
	jsr os_putc
	rts

; ==================
dump_buf:
	lda #$f
	sta loop_count
	ldy #$0
@outer_loop:
	ldx #$f
@inner_loop:
	lda input_buf, y
	jsr print_alphanum

	lda input_buf_h, y
	jsr print_alphanum

	iny
	dex
	bmi @exit_inner
	lda #' '
	jsr os_putc
	jmp @inner_loop

@exit_inner:
	jsr os_putnl

	dec loop_count
	bpl @outer_loop
	rts
.RODATA
init_message:
	.byte "Press q to exit...", $00

cmd_done_message:
	.byte "Cmd done...", $00

ready_message:
	.byte "Ready.", $00

error_message:
	.byte "Error.", $00

drq_message:
	.byte "DRQ Ready.", $00

; A.S.N.M.2.H.
