.include "std.inc"

.import oss_pagetable
.import oss_input_line, oss_input_line_ptr 
.import oss_next_token_ptr, oss_next_token_end
.import oss_receive_pos, oss_receive_size, oss_io_fun, oss_user_process
.import oss_resident_entrypoint, oss_resident_return, oss_resident_state 
.import oss_resident_event, oss_resident_eventdata, oss_input_char 
.import oss_irq_timer, oss_argc, oss_argv, oss_argv_num, oss_rand_seed 
.import oss_dt_div16 
.import oss_ide_lba_low, oss_ide_lba_mid, oss_ide_lba_high

PAGETABLE = $0200
.assert PAGETABLE = oss_pagetable, error, "PAGETABLE mismatch"

OS_STATE = $300
; INPUT_LINE = OS_STATE				; address of input line. Keep at page start to simplify ptr calculations
INPUT_LINE_LEN = $40 - $1			; capacity of input line (minus 1 for null termination)
; INPUT_LINE_PTR = INPUT_LINE + $1 + INPUT_LINE_LEN	; address of current input line ptr 
; 						; (relative to address of input line)

; NEXT_TOKEN_PTR   = INPUT_LINE_PTR + 1
; NEXT_TOKEN_END   = NEXT_TOKEN_PTR + 1

; RECEIVE_POS = NEXT_TOKEN_END + 1
; RECEIVE_SIZE = RECEIVE_POS + 2
; IO_FUN = RECEIVE_SIZE + 2
; USER_PROCESS = IO_FUN + 2
; RESIDENT_ENTRYPOINT = USER_PROCESS + 1
; RESIDENT_RETURN = RESIDENT_ENTRYPOINT + 2
; RESIDENT_STATE = RESIDENT_RETURN + 1
; RESIDENT_EVENT = RESIDENT_STATE + 1
; RESIDENT_EVENTDATA = RESIDENT_EVENT + 1
; INPUT_CHAR = RESIDENT_EVENTDATA + 1
; IRQ_TIMER = INPUT_CHAR + 1
; ARGC = IRQ_TIMER + 1
; ARGV = ARGC + 1
ARGV_NUM = 16
; RAND_SEED = ARGV + ARGV_NUM 
; DT_DIV16 = RAND_SEED + 1
; IDE_LBA_LOW = DT_DIV16 + 1
; IDE_LBA_MID = IDE_LBA_LOW + 1
; IDE_LBA_HIGH = IDE_LBA_MID + 1
; .assert IDE_LBA_HIGH = oss_ide_lba_high, error, "IDE_LBA_HIGH mismatch"
; .assert IDE_LBA_HIGH < $400, error, "os state too large"
.assert oss_ide_lba_high < $400, error, "os state too large"

.importzp zp_ptr, zp_io_addr, zp_fletch_1, zp_fletch_2, zp_io_bw_end
.importzp zp_io_bl_l, zp_io_bw_ptr, zp_io_bl_h, zp_io_bw_eof
.importzp zp_a, zp_al, zp_ah
.importzp zp_b, zp_bl, zp_bh
.importzp zp_c, zp_cl, zp_ch
.importzp zp_d, zp_dl, zp_dh
.importzp zp_e, zp_el, zp_eh
.importzp zp_mon_addr, zp_mon_addrl, zp_mon_addrh
.importzp zp_a_temp, zp_x_temp
.importzp zp_dt_count_l, zp_dt_count_h
.importzp zp_fgetc, zp_fgetc_l, zp_fgetc_h

; ZP_PTR = zp_ptr
; IO_ADDR = zp_io_addr
; FLETCH_1 = zp_fletch_1
; FLETCH_2 = zp_fletch_2
; IO_BW_END = zp_io_bw_end
; IO_BW_PTR = zp_io_bw_ptr
; IO_BW_EOF = zp_io_bw_eof
; IO_BL_L = zp_io_bl_l
; IO_BL_H = zp_io_bl_h
; AL = zp_al
; AH = zp_ah
; BL = zp_bl
; BH = zp_bh
; CL = zp_cl
; CH = zp_ch
; DL = zp_dl
; DH = zp_dh
; EL = zp_el
; EH = zp_eh
; MON_ADDR = zp_mon_addr
; MON_ADDRL = zp_mon_addr_l
; MON_ADDRH = zp_mon_addr_h
; A_TEMP = zp_a_temp
; X_TEMP = zp_x_temp
; DT_COUNT_L = zp_dt_count_l
; DT_COUNT_H = zp_dt_count_h
; FGETC_L = zp_fgetc_l
; FGETC_H = zp_fgetc_h
; FGETC = zp_fgetc

; ZP_PTR = TARGET_ADDR + 2

; IO_ADDR = ZP_PTR + 2
; FLETCH_1 = IO_ADDR + 2
; FLETCH_2 = FLETCH_1 + 1

; IO_BW_END = FLETCH_2 + 1
; IO_BW_PTR = IO_BW_END + 1
; IO_BW_EOF = IO_BW_PTR + 1

; ; reuse bytewise pointers for block based IO
; IO_BL_L = IO_BW_END
; IO_BL_H = IO_BW_PTR

; AL = IO_BW_EOF + 1
; AH = AL + 1

; BL = AH + 1
; BH = BL + 1

; CL = BH + 1
; CH = CL + 1

; DL = CH + 1
; DH = DL + 1

; EL = DH + 1
; EH = EL + 1

; MON_ADDRL = EH + 1
; MON_ADDRH = MON_ADDRL + 1
; A_TEMP = MON_ADDRH + 1
; X_TEMP = A_TEMP + 1
; DT_COUNT_L = X_TEMP + 1
; DT_COUNT_H = DT_COUNT_L + 1
; FGETC_L = DT_COUNT_H + 1
; FGETC_H = FGETC_L + 1
; .assert FGETC_H = zp_fgetc_h, error, "zp_fgetc_h mismatch"
; .assert FGETC_H < $80, error, "os zp state too large"
.assert zp_fgetc_h < $80, error, "os zp state too large"

IO_BUFFER = $0400
IO_BUFFER_L = $0400
IO_BUFFER_H = $0500

.macro set_ptr src
	ldx #<src
	stx zp_ptr
	ldx #>src
	stx zp_ptr + 1
.endmacro

.macro dispatch_command cmd_ptr, dest
.local @next
	set_ptr cmd_ptr
	jsr compare_token
	bcc @next
	jsr dest
	jmp @cleanup
@next:
.endmacro

.macro print_message_from_ptr src
	lda #<src
	ldx #>src
	jsr print_message
.endmacro

; store 16bit value (addr) into two bytes of memory at dest
.macro store_address addr, dest
	lda #<addr
	sta dest
	lda #>addr
	sta dest + 1
.endmacro

.macro save_regs
	pha
	txa
	pha
	tya
	pha
.endmacro

.macro restore_regs
	pla
	tay
	pla
	tax
	pla
.endmacro

.macro save_xy
	sta zp_a_temp
	txa
	pha
	tya
	pha
	lda zp_a_temp
.endmacro

.macro restore_xy
	sta zp_a_temp
	pla
	tay
	pla
	tax
	lda zp_a_temp
.endmacro
