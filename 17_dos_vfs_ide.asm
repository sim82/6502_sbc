.code
.import fgetc, fputc, putc, print_message, print_hex8, print_hex16, fpurge, dbg_byte, put_newline
.import update_fletch16
.import dbg_byte
.export vfs_ide_open, vfs_ide_getc, vfs_ide_write_block, vfs_ide_set_lba
.include "17_dos.inc"

; open file on uart channel 1 in block mode (512byte)
vfs_ide_open:
	save_regs
	lda #$03
	sta IDE_LBA_LOW
	lda #$00
	sta IDE_LBA_MID
	sta IDE_LBA_HIGH

	
	lda #$ff
	sta zp_io_bw_eof
	lda #$00
	sta zp_io_bl_l
	sta zp_io_bl_h
	
	lda #$20
	sta RECEIVE_SIZE
	; jsr print_hex8
	lda #$ff
	sta RECEIVE_SIZE + 1
	jmp @no_error
	; fell through both times -> error
	clc
	restore_regs
	rts

@no_error:
	lda #0
	sta zp_fletch_1
	sta zp_fletch_2
	sta zp_io_bw_eof	; clear eof

	jsr load_block_to_iobuf
	restore_regs
	rts

load_block_to_iobuf:
	jsr read_next_block_to_iobuf
	rts

vfs_ide_getc:
	save_xy
	lda zp_io_bl_l
	cmp RECEIVE_SIZE
	bne @no_eof

	lda zp_io_bl_h
	cmp RECEIVE_SIZE + 1
	beq @eof

@no_eof:
	lda zp_io_bl_h
	lsr 
	lda zp_io_bl_l
	ror
	tay
	; y contains the 'word index' (the upper 8bit of the read ptr, i.e. the index into either the high or low io buffer page)
	; the carry flag contains the lowest bit, 0 means read from low op buffer, 1 from high
		
	bcs @high_byte
	lda IO_BUFFER_L, y
	bcc @end_read ; opt: known carry state, rel. jump
@high_byte:
	lda IO_BUFFER_H, y
@end_read:

	pha ; save current byte (could use x reg...)

	; inc read pointer
	lda #$1
	clc
	adc zp_io_bl_l
	sta zp_io_bl_l
	lda #$0
	adc zp_io_bl_h
	sta zp_io_bl_h
	
	; check if end of buffer:
	; if all 9 lowest bits are 0 after pointer inc this means we stepped into a new 512byte block
	; -> needs refill
	lda zp_io_bl_h
	and #$01
	bne @skip_fill_buffer

	lda zp_io_bl_l
	bne @skip_fill_buffer

	jsr read_next_block_to_iobuf
	bcs @skip_fill_buffer
	; directly set EOF if read failed
	ldy #$FF
	sty zp_io_bw_eof
@skip_fill_buffer:
	pla
	sec
	restore_xy
	rts
@eof:
	lda #%01010101
	sta IO_GPIO0
	lda #'X'
	clc
	restore_xy
	rts


vfs_ide_set_lba:
	; sta IDE_LBA_LOW
	; stx IDE_LBA_MID
	; sty IDE_LBA_HIGH
	sta oss_ide_lba_low
	stx oss_ide_lba_mid
	sty oss_ide_lba_high	
	rts

vfs_ide_write_block:
	; sta IDE_LBA_LOW
	; stx IDE_LBA_MID
	; sty IDE_LBA_HIGH

	jsr write_iobuf_to_next_block
	rts


write_iobuf_to_next_block:
	jsr set_size
	jsr set_low
	jsr set_mid
	jsr set_high
	jsr send_write
	jsr write_block

	inc IDE_LBA_LOW
	bne @no_carry
	inc IDE_LBA_MID
	bne @no_carry
	inc IDE_LBA_HIGH
@no_carry:
	
	sec
	rts

; read 512 byte block. Treat it as 256 x 16bit words and store 
; low/high bytes in separate buffers to simplify indexing
; NOTE: this is an intermediate step to make the 'IO' layer ready for the common 512byte block size
; used by IDE and others.
read_next_block_to_iobuf:
	jsr set_size
	jsr set_low
	jsr set_mid
	jsr set_high
	jsr send_read
	jsr read_block

	inc IDE_LBA_LOW
	bne @no_carry
	inc IDE_LBA_MID
	bne @no_carry
	inc IDE_LBA_HIGH
@no_carry:
	
	sec
	rts

; ==================
set_size:
	lda #$01
	sta $fe22
	; jsr wait_ready
	rts
set_low:
	lda IDE_LBA_LOW
	; sta ARG0
	; jsr dbg_byte
	sta $fe23
	; jsr wait_ready
	rts
	
set_mid:
	lda IDE_LBA_MID
	sta $fe24
	; jsr wait_ready
	rts
	
set_high:
	lda IDE_LBA_HIGH
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
	sta zp_a_temp
@loop:
	lda $fe27
	cmp zp_a_temp
	beq @loop
	sta zp_a_temp
	sta ARG0
	; jsr dbg_byte
	jmp @loop

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
check_error:
	lda $fe27
	and #%00000001
	beq @noerror

	lda $fe27
	sta ARG0
	; println error_message
	jsr dbg_byte
	lda $fe21
	sta ARG0
	jsr dbg_byte
	jsr put_newline
@loop:
	jmp @loop
@noerror:
	rts

; ==================
read_block:
	ldx #$0
	jsr check_error
	jsr wait_ready_int
@loop:
	jsr check_drq
	bcc @end
	lda $fe20
	sta IO_BUFFER_L, x
	lda $fe28
	sta IO_BUFFER_H, x
	inx
	jmp @loop
@end:

	; stx ARG0
	; jsr os_dbg_byte
	; jsr os_putnl
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
	lda IO_BUFFER_H, x
	sta $fe28
	lda IO_BUFFER_L, x
	sta $fe20
	inx
	jmp @loop
@end:
	; stx ARG0
	; jsr os_dbg_byte
	; jsr os_putnl
	rts


msg_read_full_block:
	.byte "read full page", $0A, $0D, $00
