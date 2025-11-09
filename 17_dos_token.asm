.export reset_tokenize, read_token, retire_token, terminate_token
.include "17_dos.inc"
.code
; tokenizer
; in-place tokenize content of input line. Tokens are separated by space character.
; The tokenizer will not modify the input line but keep track of the current token
; in oss_next_token_ptr and oss_next_token_end:
;    oss_next_token_ptr: start of next token (relative to address of oss_input_line)
;    oss_next_token_end: end of next token (i.e. first char after token) this can either be a space or then end of input line
;
; normal usage:
; 1. call reset_tokenize to start tokenizer at start of input line
; 2. call read_token
;	if a token can be read oss_next_token_ptr and oss_next_token_end are set up and carry is set
;	otherwise carry is cleared (i.e. there are no more tokens) -> end loop
; 3. call retire token. This will advance oss_next_token_ptr to oss_next_token_end
; 	repeat at point (2) (i.e. the next read_token call)
reset_tokenize:
	lda #$00
	sta oss_next_token_ptr
	sta oss_next_token_end
	rts

read_token:
	; skip whitespace
	ldy oss_next_token_ptr
	cpy oss_input_line_ptr	; check for end of line
	beq @end_of_line

	lda oss_input_line, y	; read character
	jsr is_separator
	bne @after_space
	inc oss_next_token_ptr
	jmp read_token		; there was a space -> continue loop
	
@end_of_line:
	clc			; report no success: end of line was hit while looking for space
	rts

	; at this point oss_next_token_ptr must point at a valid char
@after_space:
	ldy oss_next_token_ptr
@in_token_loop:
	iny			; pre-increment (we are sure that there was a char at Y
				;		otherwise skip space code would already have returned)

	cpy oss_input_line_ptr	; check for line end
	beq @end_of_token	; 	handle like normal token end 
	lda oss_input_line, y	; check for space
	cmp #$20
	beq @end_of_token	; space also means end of token
	jmp @in_token_loop

@end_of_token:
	sty oss_next_token_end	; Y points to first char after token (either space or end of line)
	cpy oss_next_token_ptr
	; clc
	; beq @token_empty
	sec			; report success
; @token_empty:
	rts


retire_token:
	lda oss_next_token_end	
	sta oss_next_token_ptr	; advance topen pointer to previous token end ptr
	lda #$00
	sta oss_next_token_end	; invalidate previous token end ptr
	rts

terminate_token:
	save_regs
	ldy oss_next_token_end
	lda #$00
	sta oss_input_line, y
	restore_regs
	rts

is_separator:
	cmp #$20		; and check for space
	beq @exit
	cmp #$00
	beq @exit

@exit:
	rts
