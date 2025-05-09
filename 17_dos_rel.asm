.export load_relocatable_binary
.import print_hex16, print_hex8, put_newline, fgetc_buf, putc
.import alloc_page_span, getc_blocking, putc, print_dec, put_newline, print_message, file_open_raw
.import get_argn, get_arg
.import get_event, event_return
.import os_func_table
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
import:
	jsr fgetc_buf
	tax
	bcc @eof
	; expect less than 256 imports...
	check_byte $00
	lda #'i'
	jsr putc
	lda #':'
	jsr putc
	txa
	beq @exit
	jsr print_hex8
	jsr put_newline

	txa
	beq @exit
	
@loop:
	jsr fgetc_buf
	tay ; zero test A
	beq @symbol_end
	jsr putc
	jmp @loop

@symbol_end:
	jsr put_newline
	dex
	bne @loop
	
@exit:
	sec
	rts
@eof:
	lda #%00001101
	sta IO_GPIO0
	clc
	rts
@error:
	lda #%00001110
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
	bne @skip_extended_inc
	jsr reloc_extended_inc
	jmp @loop

@skip_extended_inc:
	clc
	; add to reloc address
	adc CL
	sta CL
	lda #00
	adc CH
	sta CH
	lda CL
	ldx CH
	; jsr print_hex16
	; jsr put_newline

	; read type
	jsr fgetc_buf
	bcc @eof

	cmp #$80
	bne @skip_import
	jsr reloc_import
	bcc @error
	jmp @loop

@skip_import:
	and #$f0
	cmp #$80

	bne @skip_word

	jsr reloc_word
	bcc @error
	jmp @loop

@skip_word:
	cmp #$40
	bne @skip_high

	jsr reloc_high
	bcc @error
	jmp @loop

@skip_high:
	cmp #$20
	bne @error
	
	; ignore...
	lda #','
	jsr putc
	jmp @loop

@done:
	jsr put_newline
	sec
	rts
	
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


reloc_extended_inc:
	lda #254
	clc
	adc CL
	sta CL
	lda #00
	adc CH
	sta CH
	lda CL
	ldx CH
	lda #'>'
	jsr putc
	jsr put_newline
	sec
	rts


reloc_import:
	; only supprt one import for now
	; check_byte $00
	jsr fgetc_buf
	bcc @eof
	asl
	tax
	check_byte $00
	; lda #$aa
	; lda #<alloc_page_span
	lda os_func_table, x
	ldy #$00
	sta (CL), y
	
	; lda #>alloc_page_span
	lda os_func_table + 1, x
	; lda #$bb
	iny
	sta (CL), y
		
	lda #'i'
	jsr putc
	sec
	rts

@eof:
@error:
	clc
	rts

reloc_word:
	; super primitive: just add base to high adress part...

	ldy #$01
	lda (CL), y
	clc
	; adc #$d0
	adc DH
	sta (CL), y
	lda #'.'
	jsr putc
	sec
	rts

reloc_high:
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
	lda #'^'
	jsr putc
	sec
	rts
@eof:
@error:
	clc
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
	; expect tbase to be a 00
	check_byte $00
	check_byte $00
	
	; 	tlen
	read_word AL
	
	; jump data seg
	ldx #4
	jsr skipx

	read_word BL
	lda BL ; expect base of bss to be mod 256
	bne @error
	read_word CL
	
	lda CL ; expect size of bss to be mod 256
	bne @error
	; jump zbase / stack size
	ldx #6
	jsr skipx

	jsr skip_extra
	lda AL
	ldx AH
	
 	jsr print_hex16
	jsr put_newline

	lda CL
	ldx CH
	
 	jsr print_hex16
	jsr put_newline

	jmp stream_bin_p2 ; split due to cond branch bounds
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

stream_bin_p2:
	lda AH
	ldx AL ; check if size is already mod 256
	beq @no_plus1
	; ldx #$00
	; stx AL
	clc
	adc #$01
@no_plus1:
	clc
	adc CH
	
	jsr alloc_page_span
	sta DH
	lda #$00
	sta DL
	
	; now there should be the program code...
	jsr copy_code
	; ldx AL
	; jsr skipx
	; expect empty missing symbol table
	; check_byte $00
	; check_byte $00

	jsr import
	bcc @error

	jsr reloc
	; preserve carry flag!
	
@reloc_error:
	rts
	

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

load_relocatable_binary:
	jsr file_open_raw
	bcc @error
	jsr stream_bin
	bcc @error

	ldx DH
	stx RECEIVE_POS + 1
	stx MON_ADDRH
	lda DL
	sta RECEIVE_POS
	sta MON_ADDRL
	
	jsr print_hex16
	jsr put_newline
	
	print_message_from_ptr @fletch16_msg
	lda FLETCH_1
	ldx FLETCH_2
	jsr print_hex16
	jsr put_newline
	sec
	rts

@error:
	clc
	rts
@fletch16_msg:
	.byte "done. ", $0A, $0D, "fletch16: ", $00

; .INCLUDE "os_functable.inc"
; os_func_table:
; 	.WORD alloc_page_span
; 	.WORD getc_blocking
; 	.WORD putc
; 	.WORD file_open_raw
; 	.WORD fgetc_buf
; 	.WORD print_dec
; 	.WORD put_newline
; 	.WORD print_message
; 	.WORD get_argn
; 	.WORD get_arg
; 	.WORD get_event
; 	.WORD event_return

