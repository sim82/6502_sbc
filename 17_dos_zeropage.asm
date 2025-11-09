.include "std.inc"
.export zp_ptr, zp_io_addr, zp_fletch_1, zp_fletch_2, zp_io_bw_end
.export zp_io_bl_l, zp_io_bw_ptr, zp_io_bl_h, zp_io_bw_eof
.export zp_a, zp_al, zp_ah
.export zp_b, zp_bl, zp_bh
.export zp_c, zp_cl, zp_ch
.export zp_d, zp_dl, zp_dh
.export zp_e, zp_el, zp_eh
.export zp_mon_addr, zp_mon_addrl, zp_mon_addrh
.export zp_a_temp, zp_x_temp
.export zp_dt_count_l, zp_dt_count_h
.export zp_fgetc, zp_fgetc_l, zp_fgetc_h

.export oss_pagetable
.export oss_input_line, oss_input_line_ptr
.export oss_next_token_ptr, oss_next_token_end
.export oss_receive_pos, oss_receive_size, oss_io_fun, oss_user_process
.export oss_resident_entrypoint, oss_resident_return, oss_resident_state
.export oss_resident_event, oss_resident_eventdata, oss_input_char
.export oss_irq_timer, oss_argc, oss_argv, oss_rand_seed
.export oss_dt_div16
.export oss_ide_lba_low, oss_ide_lba_mid, oss_ide_lba_high


.ZEROPAGE
    .res TARGET_ADDR + $2
zp_ptr: .res $2
zp_io_addr: .res $2
zp_fletch_1: .res $1
zp_fletch_2: .res $1
zp_io_bw_end: 
zp_io_bl_l: .res $1
zp_io_bw_ptr:
zp_io_bl_h: .res $1
zp_io_bw_eof: .res $1 
zp_a:
zp_al: .res $1
zp_ah: .res $1
zp_b:
zp_bl: .res $1
zp_bh: .res $1
zp_c:
zp_cl: .res $1
zp_ch: .res $1
zp_d:
zp_dl: .res $1
zp_dh: .res $1
zp_e:
zp_el: .res $1
zp_eh: .res $1
zp_mon_addr:
zp_mon_addrl: .res $1
zp_mon_addrh: .res $1
zp_a_temp: .res $1
zp_x_temp: .res $1
zp_dt_count_l: .res $1
zp_dt_count_h: .res $1
zp_fgetc:
zp_fgetc_l: .res $1
zp_fgetc_h: .res $1

.segment "PAGETABLE"
oss_pagetable: .res $100

.segment "OS_STATE"
oss_input_line: .res $40
oss_input_line_ptr: .res $1
oss_next_token_ptr: .res $1
oss_next_token_end: .res $1
oss_receive_pos: .res $2
oss_receive_size: .res $2
oss_io_fun: .res $2
oss_user_process: .res $1
oss_resident_entrypoint: .res $2
oss_resident_return: .res $1
oss_resident_state: .res $1
oss_resident_event: .res $1
oss_resident_eventdata: .res $1
oss_input_char: .res $1
oss_irq_timer: .res $1
oss_argc: .res $1
oss_argv: .res 16
oss_rand_seed: .res $1
oss_dt_div16: .res $1
oss_ide_lba_low: .res $1
oss_ide_lba_mid: .res $1
oss_ide_lba_high: .res $1