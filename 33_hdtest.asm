
.INCLUDE "std.inc"
.INCLUDE "os.inc"

.ZEROPAGE
last_stat: .res $1
loop_count: .res $1
lba_low: .res $1

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
	println init_message
	lda #OS_EVENT_RETURN_KEEP_RESIDENT
	jsr os_event_return
	rts

event_key:
	txa
	cmp #'t'
	beq tread_sector
	cmp #'r'
	beq tread1
	cmp #'i'
	beq tidentify
	cmp #'c'
	beq tcheck_rdy
	cmp #'s'
	beq tprint_status
	cmp #'e'
	beq tselect
	cmp #'b'
	beq tbenign_write
	cmp #'d'
	beq tdump_input
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

tread_sector:
	jmp read_sector
tread1:
	jmp read1
tidentify:
	jmp identify
tcheck_rdy:
	jmp check_rdy
tprint_status:
	jmp print_status
tselect:
	jmp select
tbenign_write:
	jmp benign_write
tdump_input:
	jmp dump_input
	
event_timer:
	lda #OS_EVENT_RETURN_KEEP_RESIDENT
	jsr os_event_return

	rts

exit_resident:
	println cmd_done_message
	lda #OS_EVENT_RETURN_KEEP_RESIDENT
	jsr os_event_return
	rts 

; =======================================
; commands
; ======================================

; ==================
read_sector:
	lda #$01
	sta $fe22
	lda lba_low
	inc lba_low
	sta $fe23
	lda #$30
	sta $fe24
	lda #$00
	sta $fe25

	lda #$e0
	sta $fe26
	lda #$20
	sta $fe27
	; jsr read_block

	jmp exit_resident

; ==================
read1:
	jsr read_block
	jmp exit_resident
	; jmp dump_input


; ==================
dump_input:
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
	jmp exit_resident

; ==================
select:
	lda #$e0
	sta $fe26
	jmp exit_resident

; ==================
identify:
	lda #$ec
	sta $fe27
	jmp exit_resident
	
; ==================
print_status:
	lda $fe27
	sta ARG0
	jsr os_dbg_byte
	jsr os_putnl
	jmp exit_resident
	
; ==================
benign_write:
	lda #$00
	sta $fe21
	jmp exit_resident

; =======================================
; utility functions
; ======================================
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
	rts

; ==================
read_block:
	ldx #$0
@loop:
	lda $fe20
	sta input_buf, x
	lda $fe28
	sta input_buf_h, x
	inx
	bne @loop
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

.RODATA
init_message:
	.byte "Press q to exit...", $00

cmd_done_message:
	.byte "Cmd done...", $00

ready_message:
	.byte "Ready.", $00

error_message:
	.byte "Error.", $00

; A.S.N.M.2.H.
