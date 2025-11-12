.code
.import fgetc, fputc, putc, print_message, print_hex8, print_hex16, fpurge, dbg_byte, put_newline
.import update_fletch16
.import dbg_byte
.export vfs_ide_open, vfs_ide_getc, vfs_ide_write_block, vfs_ide_set_lba
.include "17_dos.inc"

; open file on uart channel 1 in block mode (512byte)
vfs_ide_open:
	save_regs
	lda #$01
	sta oss_ide_lba_low
	lda #$00
	sta oss_ide_lba_mid
	sta oss_ide_lba_high

	
	lda #$ff
	sta zp_io_bw_eof
	lda #$00
	sta zp_io_bl_l
	sta zp_io_bl_h
	
	lda #$20
	sta oss_receive_size
	; jsr print_hex8
	lda #$ff
	sta oss_receive_size + 1
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
	cmp oss_receive_size
	bne @no_eof

	lda zp_io_bl_h
	cmp oss_receive_size + 1
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
	; sta oss_ide_lba_low
	; stx oss_ide_lba_mid
	; sty oss_ide_lba_high
	sta oss_ide_lba_low
	stx oss_ide_lba_mid
	sty oss_ide_lba_high	
	rts

vfs_ide_write_block:
	save_regs
	jsr write_iobuf_to_next_block
	restore_regs
	rts


write_iobuf_to_next_block:
	jsr set_size
	jsr set_low
	jsr set_mid
	jsr set_high
	jsr send_write
	jsr write_block

	inc oss_ide_lba_low
	bne @no_carry
	inc oss_ide_lba_mid
	bne @no_carry
	inc oss_ide_lba_high
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

	inc oss_ide_lba_low
	bne @no_carry
	inc oss_ide_lba_mid
	bne @no_carry
	inc oss_ide_lba_high
@no_carry:
	
	sec
	rts

; ==================
set_size:
	lda #$01
	sta IO_IDE_SIZE
	; jsr wait_ready
	rts
set_low:
	lda oss_ide_lba_low
	; sta ARG0
	; jsr dbg_byte
	sta IO_IDE_LBA_LOW
	; jsr wait_ready
	rts
	
set_mid:
	lda oss_ide_lba_mid
	sta IO_IDE_LBA_MID
	; jsr wait_ready
	rts
	
set_high:
	lda oss_ide_lba_high
	sta IO_IDE_LBA_HIGH
	; jsr wait_ready
	rts
	
send_read:
	lda #$e0
	sta IO_IDE_DRIVE_HEAD
	lda #IDE_CMD_READ
	sta IO_IDE_CMD
	; jsr wait_ready
	jsr wait_drq
	rts
		
send_write:
	lda #$e0
	sta IO_IDE_DRIVE_HEAD
	lda #IDE_CMD_WRITE
	sta IO_IDE_CMD
	; jsr wait_ready
	jsr wait_drq
	rts
	
check_rdy:
	lda #0
	sta zp_a_temp
@loop:
	lda IO_IDE_STATUS
	cmp zp_a_temp
	beq @loop
	sta zp_a_temp
	sta ARG0
	; jsr dbg_byte
	jmp @loop

; ==================
wait_drq:
	lda IO_IDE_STATUS
	and #%10001000
	cmp #%00001000
	bne wait_drq

	; println drq_message
	rts
; ==================
check_drq:
	lda IO_IDE_STATUS
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
	lda IO_IDE_STATUS
	and #%00000001
	bne @error
	sec
@loop:
	lda IO_IDE_STATUS
	and #%10000000
	bne @loop
	rts
@error:
	clc
	rts

; ==================
check_error:
	lda IO_IDE_STATUS
	and #%00000001
	beq @noerror

	lda IO_IDE_STATUS
	sta ARG0
	; println error_message
	jsr dbg_byte
	lda IO_IDE_ERROR
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
	lda IO_IDE_DATA_LOW
	sta IO_BUFFER_L, x
	; get high byte from latch
	lda IO_IDE_DATA_HIGH
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
	; write high byte to latch first
	lda IO_BUFFER_H, x
	sta IO_IDE_DATA_HIGH
	lda IO_BUFFER_L, x
	sta IO_IDE_DATA_LOW
	inx
	jmp @loop
@end:
	; stx ARG0
	; jsr os_dbg_byte
	; jsr os_putnl
	rts


msg_read_full_block:
	.byte "read full page", $0A, $0D, $00
