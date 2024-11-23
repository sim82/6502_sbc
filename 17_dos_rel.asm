.export stream_bin
.import print_hex16, print_hex8, put_newline, fgetc_buf, putc
.include "17_dos.inc"
.include "std.inc"
.code


.macro check_byte b
	jsr fgetc_buf
	bcc @eof
	cmp #b

	bne @error
.endmacro

.macro read_word addr
	jsr fgetc_buf
	bcc @eof
	sta addr

	jsr fgetc_buf
	bcc @eof
	sta addr + 1
.endmacro

skip16:
	ldy BH
	ldx BL
	
@loop:
	beq @dech
	dex
	jsr fgetc_buf
	jsr putc
	bcc @eof
	jmp @loop
	
@dech:
	cpy #00
	beq @done
	dey
	ldx #$ff
	jmp @loop
	
@eof:
	lda #%00000001
	sta IO_GPIO0
@done:
	rts

skipx:
	txa
	jsr print_hex8
	jsr put_newline
@loop:
	beq @done
	jsr fgetc_buf

	bcc @eof
	; txa
	; jsr print_hex8
	dex
	jmp @loop
@eof:
	lda #%00000001
	sta IO_GPIO0
@done:
	; jsr put_newline
	rts

skip_extra:
@extra_loop:
	jsr fgetc_buf
	bcc @eof
	; len 0 means end of extra
	cmp #00
	beq @end_extra

	; skip extra data
	tax
	dex ; size includes the length field -> one less byte to skip
	jsr skipx
	jmp @extra_loop
@eof:
	lda #%00000001
	sta IO_GPIO0
@end_extra:
	; jsr put_newline
	rts

check_header:
	; check header
	; 	non c64 marker
	check_byte $01
	check_byte $00
	;	magick
	check_byte $6f
	check_byte $36
	check_byte $35
	;	version
	check_byte $00
	;	mode
	check_byte $00
	check_byte $00

	sec
	rts

@eof:
	lda #%00000001
	sta IO_GPIO0
	clc
	rts
@error:
	lda #%00000010
	sta IO_GPIO0
	clc
	rts

reloc:
	lda #$3f
	sta CH
	lda #$ff
	sta CL
	
@loop:
	; read offset
	jsr fgetc_buf
	bcc @eof

	cmp #00
	beq @done
	clc
	; add to reloc address
	adc CL
	sta CL
	lda #00
	adc CH
	sta CH
	lda CL
	ldx CH
	jsr print_hex16
	jsr put_newline

	; read type
	jsr fgetc_buf
	bcc @eof
	; only support WORD size in text segment
	cmp #$82
	bne @error

	jmp @loop

@eof:
	lda #%00000101
	sta IO_GPIO0
	clc
	rts
@error:
	lda #%00000110
	sta IO_GPIO0
	clc
	rts
@done:
	sec
	rts

stream_bin:
	jsr check_header
	bcs @header_ok
	; pass through error state
	rts
@header_ok:
	; 	tbase
	read_word AL
	; 	tlen
	read_word AL
	
	;	jump non txt base / len fields (14 bytes) for now
	ldx #14
	jsr skipx
	jsr skip_extra
	; now there should be the program code...
	lda AL
	ldx AH
	
 	jsr print_hex16
	jsr put_newline
	ldx AL
	jsr skipx
	; expect empty missing symbol table
	check_byte $00
	check_byte $00

	jsr reloc
	
	rts
	

@eof:
	lda #%00000001
	sta IO_GPIO0
	rts
@error:
	lda #%00000010
	sta IO_GPIO0
	rts
