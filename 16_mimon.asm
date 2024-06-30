.AUTOIMPORT +
.INCLUDE "std.inc"
.SEGMENT "VECTORS"
	.WORD $8000

.SEGMENT "IO"
	.BYTE $55
	
CUR_STATE = $0400
STEP_SIZE = $0401
POKE_NIBBLE0 = $0402

ECHO_ON = $0404

TARGET_ADDR = $80

STATE_INIT = 0
STATE_POKE0 = 1
STATE_POKE1 = 2
STATE_TARGET0 = 3
STATE_TARGET1 = 4
STATE_TARGET2 = 5
STATE_TARGET3 = 6

.CODE
	jsr disp_init
	
	lda #$00
	tax
	tay
hello:
	jsr check_busy
	lda message, X
	beq @after_hello
	sta IO_DISP_DATA
	inx
	jmp hello
@after_hello:
	jsr disp_linefeed

	lda #$00
	sta CUR_STATE
	sta STEP_SIZE
	lda #<IO_GPIO0
	sta TARGET_ADDR
	lda #>IO_GPIO0
	sta TARGET_ADDR+1
	lda #$01
	sta ECHO_ON
	
	; Bit 7: Select CR = 0
	; Bit 6: CDR/ACR (don't care)
	; Bit 5: Num stop bits (0=1, 1-2)
	; Bit 4: Echo mode (0=disabled, 1=enabled)
	; Bit 3-0: baud divisor (1110 = 3840)
	; write CR
	lda #%00001110
	sta IO_UART_CR1

	; Bit 7: Select FR = 1
	; Bit 6,5: Num Bits (11 = 8)
	; Bit 4,3: Parity mode (don't care)
	; Bit 2: Parity Enable / Disable (1/0)
	; Bit 1,0: DTR/RTS control (don't care)
	; write FR
	lda #%11100000
	sta IO_UART_FR1

	lda #%11000001
	sta IO_UART_IER1

		
@loop:
	; lda #$00
	; sta NUM1+1
	; lda CUR_STATE
	; sta NUM1
	; jsr check_busy
	; jsr out_dec
	jsr uart_read_blocking
	ldy ECHO_ON
	beq @skip_echo
	jsr uart_write_blocking
@skip_echo:
	jsr eval_state
	jmp @loop

		
state_init:
	pla
	cmp #'p'
	beq @poke
	cmp #'t'
	beq @target
	cmp #'a'
	beq @enable_auto_inc
	cmp #'A'
	beq @disable_auto_inc
	cmp #'e'
	beq @enable_echo
	cmp #'E'
	beq @disable_echo
	cmp #'r'
	beq @run
	rts

@poke:
	lda #'p' 
	sta IO_DISP_DATA
	lda #STATE_POKE0
	jmp goto_state
@target: 
	lda #'t' 
	sta IO_DISP_DATA
	lda #STATE_TARGET0
	jmp goto_state

@enable_auto_inc:
	lda #'a' 
	sta IO_DISP_DATA
	lda #$01
	jmp set_step_size

@disable_auto_inc:
	lda #'A' 
	sta IO_DISP_DATA
	lda #$00
	jmp set_step_size
@enable_echo:
	lda #'e'
	sta IO_DISP_DATA
	lda #$01
	sta ECHO_ON
	jmp goto_init

@disable_echo:
	lda #'E'
	sta IO_DISP_DATA
	lda #$00
	sta ECHO_ON
	jmp goto_init
@run:
	lda #'r' 
	sta IO_DISP_DATA
	jmp (TARGET_ADDR)

eval_state:
	pha
	lda CUR_STATE
	cmp #STATE_INIT
	beq state_init
	cmp #STATE_POKE0
	beq state_poke0
	cmp #STATE_POKE1
	beq state_poke1
	cmp #STATE_TARGET0
	beq state_target0
	cmp #STATE_TARGET1
	beq state_target1
	cmp #STATE_TARGET2
	beq state_target2
	cmp #STATE_TARGET3
	beq state_target3
	pla
	rts
state_poke0:
	pla
	jsr decode_nibble_high
	bcs goto_init
	sta POKE_NIBBLE0
	lda #STATE_POKE1
	jmp goto_state

state_poke1:
	pla
	jsr decode_nibble
	bcs goto_init
	ora POKE_NIBBLE0
	ldx #$00
	sta (TARGET_ADDR, X)
	lda STEP_SIZE
	clc
	adc TARGET_ADDR
	sta TARGET_ADDR
	bcc @no_dot
	lda #'.'
	sta IO_DISP_DATA
	lda #$00
	adc TARGET_ADDR+1
	sta TARGET_ADDR+1
@no_dot:
	lda #STATE_POKE0
	jmp goto_state


state_target0:
	pla
	jsr decode_nibble_high
	sta TARGET_ADDR+1
	lda #STATE_TARGET1
	jmp goto_state
state_target1:
	pla
	jsr decode_nibble
	ora TARGET_ADDR+1
	lda #STATE_TARGET2
	jmp goto_state
state_target2:
	pla
	jsr decode_nibble_high
	sta TARGET_ADDR
	lda #STATE_TARGET3
	jmp goto_state
state_target3:
	pla
	jsr decode_nibble
	ora TARGET_ADDR
	jmp goto_init

set_step_size:
	sta STEP_SIZE
goto_init:
	lda #STATE_INIT
goto_state:
	sta CUR_STATE
	rts
uart_read_blocking:
@loop:
	; check transmit data register empty
	lda IO_UART_ISR1
	and #%00000001
	beq @loop
	lda IO_UART_RDR1
	rts

uart_write_blocking:
	pha
@loop:
	lda IO_UART_ISR1
	and #%01000000
	beq @loop
	pla
	sta IO_UART_TDR1
	rts

decode_nibble_high:
	jsr decode_nibble
	bcs @exit
	asl
	asl
	asl
	asl
@exit:
	rts
decode_nibble:
	; sta IO_DISP_DATA
	cmp #'0'
	bmi @bad_char

	cmp #':'
	bpl @high
	sec
	sbc #'0'
	; pha
	; lda #$00
	; sta NUM1+1
	; pla
	; sta NUM1
	; jsr out_dec
	clc
	rts

@high:
	cmp #'a'
	bmi @bad_char
	cmp #'g'
	bpl @bad_char
	sec
	sbc #('a' - 10)
	clc
	rts

@bad_char:
	sec
	rts

error:
	lda #$55
	sta IO_GPIO0
	jmp error
; IO_UART_CRFR1  = $e021
; IO_UART_TDRD1  = $e023
.RODATA
message:
	.byte "Welcome to MiMon!", $0D, $0A, $00
	; .asciiz "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqqrstuvwxyz"
