
.AUTOIMPORT +
.INCLUDE "std.inc"
.SEGMENT "VECTORS"
	.WORD $8000

INPUT_LINE = $0200				; address of input line
INPUT_LINE_LEN = $50				; capacity of input line
INPUT_LINE_PTR = INPUT_LINE + INPUT_LINE_LEN	; address of current input line ptr 
						; (relative to address of input line)

NEXT_TOKEN_PTR   = INPUT_LINE_PTR + 1
NEXT_TOKEN_END   = NEXT_TOKEN_PTR + 1

.CODE
	; init local vars
	lda #$00
	sta INPUT_LINE_PTR
mainloop:
	jsr read_input
	jmp mainloop

read_input:
	jsr getc
	bcc read_input 		; busy wait for character
	cmp #$0a 		; ignore LF / \n
	beq read_input
	cmp #$0d 		; enter key is CR / \r 
	bne @no_enter_key
	jsr put_newline		; handle enter: - put newline
	jsr exec_input_line     ;               - execute input line
	rts
@no_enter_key:
	cmp #$08		; handle backspace
	bne @normal_char
	ldy INPUT_LINE_PTR	; check if input line is empty -> ignore backspace
	beq mainloop
	dec INPUT_LINE_PTR	; delete last char (dec ptr)

	; rub-out character on terminal
	jsr putc		; send the backspace (move cursor back)
	lda #' '		; overwrite with space
	jsr putc
	lda #$08		; send another backspace to move cursor back onto space
	jsr putc
	jmp mainloop
@normal_char:
	; TODO: ignore non-printable chars
	ldy INPUT_LINE_PTR	; append normal char to input line
	cpy #INPUT_LINE_LEN	;   check if input line is full
	beq @buf_full
	sta INPUT_LINE, y	;   store char at current input line ptr
	jsr putc		;   local echo
	inc INPUT_LINE_PTR	;   in-place increase input line ptr
	; fall through
@buf_full:
	rts

exec_input_line:
	ldy #$0
@loop:
	cpy INPUT_LINE_PTR
	beq @end
 	lda INPUT_LINE, y
	jsr putc
	iny
	jmp @loop

@end:
	jsr put_newline
	jsr reset_tokenize
@token_loop:
	jsr read_token
	bcc @token_end
	ldy NEXT_TOKEN_PTR

@in_token_loop:
	cpy NEXT_TOKEN_END
	beq @end_of_token
	lda INPUT_LINE, y
	jsr putc
	iny
	jmp @in_token_loop

@end_of_token:
	jsr retire_token
	jsr put_newline
	jmp @token_loop

@token_end:
	ldy #$0
	sty INPUT_LINE_PTR
	jsr put_newline
	rts
; tokenizer
; in-place tokenize content of input line. Tokens are separated by space character.
; The tokenizer will not modify the input line but keep track of the current token
; in NEXT_TOKEN_PTR and NEXT_TOKEN_END:
;    NEXT_TOKEN_PTR: start of next token (relative to address of INPUT_LINE)
;    NEXT_TOKEN_END: end of next token (i.e. first char after token) this can either be a space or then end of input line
;
; normal usage:
; 1. call reset_tokenize to start tokenizer at start of input line
; 2. call read_token
;	if a token can be read NEXT_TOKEN_PTR and NEXT_TOKEN_END are set up and carry is set
;	otherwise carry is cleared (i.e. there are no more tokens) -> end loop
; 3. call retire token. This will advance NEXT_TOKEN_PTR to NEXT_TOKEN_END
; 	repeat at point (2) (i.e. the next read_token call)
reset_tokenize:
	lda #$00
	sta NEXT_TOKEN_PTR
	sta NEXT_TOKEN_END
	rts

read_token:
	; skip whitespace
	ldy NEXT_TOKEN_PTR
	cpy INPUT_LINE_PTR	; check for end of line
	beq @end_of_line

	lda INPUT_LINE, y	; read character
	cmp #$20		; and check for space
	bne @after_space
	inc NEXT_TOKEN_PTR
	jmp read_token		; there was a space -> continue loop
	
@end_of_line:
	clc			; report no success: end of line was hit while looking for space
	rts

	; at this point NEXT_TOKEN_PTR must point at a valid char
@after_space:
	ldy NEXT_TOKEN_PTR
@in_token_loop:
	iny			; pre-increment (we are sure that there was a char at Y
				;		otherwise skip space code would already have returned)

	cpy INPUT_LINE_PTR	; check for line end
	beq @end_of_token	; 	handle like normal token end 
	lda INPUT_LINE, y	; check for space
	cmp #$20
	beq @end_of_token	; space also means end of token
	jmp @in_token_loop

@end_of_token:
	sty NEXT_TOKEN_END	; Y points to first char after token (either space or end of line)
	sec			; report success
	rts


retire_token:
	lda NEXT_TOKEN_END
	sta NEXT_TOKEN_PTR
	lda #$00
	sta NEXT_TOKEN_END
	rts
putc:
V_OUTP:
	pha
@loop:
	lda IO_UART_ISR1
	and #%01000000
	beq @loop
	pla
	sta IO_UART_TDR1
	rts

getc:
V_INPT:
@loop:
	; check transmit data register empty
	lda IO_UART_ISR1
	and #%00000001
	beq @no_keypress
	lda IO_UART_RDR1
        sec
	rts

@no_keypress:
        clc
	rts


put_newline:
	lda #$0a
	jsr putc
	lda #$0d
	jsr putc
	rts


; low in a, high in x
print_hex16:
	pha
	txa
	jsr print_hex8
	pla
	jsr print_hex8
	rts

; arg in a
print_hex8:
	pha
	jsr print_hex4_high
	pla
	jsr print_hex4
	rts

print_hex4_high:
	lsr
	lsr
	lsr
	lsr
print_hex4:
	and #$f
	cmp #10
	bcs @in_a_to_f_range
	clc
	adc #'0'
	jmp @output
@in_a_to_f_range:
	; cmp $16
	; bmi @error
	; adc #('a' - 10)
	clc
	adc #($61 - $a)
	jmp @output
; @error:
; 	lda #'X'
@output:
	jsr putc
	rts
