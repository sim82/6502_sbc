.export stream_bin
.import print_hex16, print_hex8, put_newline, fgetc_buf, putc
.import alloc_page_span
.include "17_dos.inc"
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; skip16:
; skip variable sized block: read 16bit value and use that as size to 
; skip a block of data in the input file.

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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; skipx:
; read & ignore X bytes from input file

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

dumpx:
	txa
@loop:
	beq @done
	jsr fgetc_buf

	bcc @eof
	jsr putc
	; txa
	; jsr print_hex8
	dex
	jmp @loop
@eof:
	lda #%00000001
	sta IO_GPIO0
@done:
	jsr put_newline
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; skip_extra:
; skip / read extra header fields (optionally dump some information)

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

	jsr fgetc_buf
	bcc @eof

	dex ; consume type field

	; hyper crappy: print some blurbs
	cmp #$0
	bne @not_filename
	lda #'f'
	jsr putc
	lda #':'
	jsr putc
	jsr dumpx
	jmp @extra_loop
@not_filename:
	cmp #$4
	bne @not_creation
	lda #'c'
	jsr putc
	lda #':'
	jsr putc
	jsr dumpx
	jmp @extra_loop
@not_creation:
	cmp #$2
	bne @not_assembler
	lda #'a'
	jsr putc
	lda #':'
	jsr putc
	jsr dumpx
	jmp @extra_loop
@not_assembler:
	jsr skipx
	jmp @extra_loop
@eof:
	lda #%00000001
	sta IO_GPIO0
@end_extra:
	; jsr put_newline
	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; check_header:
; do crude verification that the binary header is exactly as expected

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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; reloc:
; read relocation information and apply to loaded binary

reloc:
	; load reloc base address from D. Decrease by one since reloc info is
	; relative to the byte before the start of the code segment.
	; NOTE: expects a page aligned pointer.
	; lda #$cf
	lda DH
	sta CH
	dec CH
	; lda #$ff
	lda DL
	sta CL
	dec CL

	; print it
	ldx CH
	lda CL
	jsr print_hex16
	
@loop:
	; read offset
	jsr fgetc_buf
	bcc @eof

	cmp #00
	beq @done
	cmp #$ff

	bne @no_extended_inc
	lda #254
	clc
	adc CL
	sta CL
	lda #00
	adc CH
	sta CH
	lda CL
	ldx CH
	lda #'.'
	jsr putc
	jsr put_newline
	; restart
	jmp @loop
	
@no_extended_inc:
	clc
	; add to reloc address
	adc CL
	sta CL
	lda #00
	adc CH
	sta CH
	lda CL
	ldx CH
	lda #'.'
	jsr putc
	; jsr print_hex16
	; jsr put_newline

	; read type
	jsr fgetc_buf
	bcc @eof
	; only support WORD size in text segment
	cmp #$82
	bne @not_word

	; super primitive: just add $d0 to high adress part...

	ldy #$01
	lda (CL), y
	clc
	; adc #$d0
	adc DH
	sta (CL), y
	jmp @loop
@not_word:
	cmp #$42
	bne @not_high

	; lda #$d0
	ldy #$00
	lda (CL), y
	clc
	; adc #$d0
	adc DH
	sta (CL), y

	; skip low byte stored after reloc entry
	jsr fgetc_buf
	bcc @eof
	jmp @loop

@not_high:
	cmp #$22
	; ignore...
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
	jsr put_newline
	sec
	rts



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; copy_code:
; read code segment and put it into the target location.

copy_code:
	; lda #$d0
	lda DH
	sta CH
	; lda #$00
	lda DL
	sta CL

@loop:
	lda AH
	jsr print_hex8
	jsr put_newline
	lda AH
	beq @single_page

	; jsr print_hex8
	; jsr put_newline

	jsr copy_code_full_page
	dec AH
	; inc CH
	jmp @loop

@single_page:
	ldx AL
	jsr copy_code_single_page

	rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; copy_code_full_page:
; internal helper for reading a whole page of code

copy_code_full_page:
	; lda #$d0
	; sta CH
	; lda #$00
	; sta CL

	ldx #$00
	lda #$01 ; super hacky: skip zero test on first iter...
	jmp copy_code_loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; copy_code_single_page:
; internal helper for reading a partially filled page of code

copy_code_single_page:
	; lda #$d0
	; sta CH
	; lda #$00
	; sta CL
	
	txa ; hacky: zero test x before entering the loop...
copy_code_loop:
	beq @done
	jsr fgetc_buf
	bcc @eof

	ldy #00
	sta (CL), y

	; jsr print_hex8
	; jsr put_newline
	; txa
	; jsr print_hex8
	; jsr put_newline
	clc
	lda #01
	adc CL
	sta CL
	lda #00
	adc CH
	sta CH
	dex
	jmp copy_code_loop
	
@eof:
	lda #%00001001
	sta IO_GPIO0
	clc
	rts
@error:
	lda #%00001010
	sta IO_GPIO0
	clc
@done:
	rts
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; stream_bin:
; main entry point into relocating o65 binary loader. Expects binary file
; to be opened for buffered byte input.

stream_bin:
	; lda #$c0
	; sta DH
	; lda #$00
	; sta DL
	
	jsr check_header
	bcs @header_ok
	; pass through error state
	rts
@header_ok:
	; 	tbase
	read_word AL
	; 	tlen
	read_word AL
	
	; jump non txt base / len fields (14 bytes) for now
	ldx #14
	jsr skipx
	jsr skip_extra
	; now there should be the program code...
	lda AL
	ldx AH
	
 	jsr print_hex16
	jsr put_newline

	lda AH
	; round up page num (NOTE: handle case where size is mod 256)
	clc
	adc #$01
	jsr alloc_page_span
	sta DH
	lda #$00
	sta DL
	
	jsr copy_code
	; ldx AL
	; jsr skipx
	; expect empty missing symbol table
	check_byte $00
	check_byte $00


	jsr reloc
	; preserve carry flag!
	
@reloc_error:
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
