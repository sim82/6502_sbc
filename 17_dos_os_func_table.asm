.IMPORT alloc_page_span, getc_blocking, putc, vfs_open, vfs_getc, print_dec, put_newline, print_message, get_argn, get_arg, get_event, event_return, free_page_span, print_fletch16, rand_8, set_direct_timer, dbg_byte, vfs_next_block, vfs_ide_write_block
.EXPORT os_func_table

os_func_table:
    .WORD alloc_page_span
    .WORD getc_blocking
    .WORD putc
    .WORD vfs_open
    .WORD vfs_getc
    .WORD print_dec
    .WORD put_newline
    .WORD print_message
    .WORD get_argn
    .WORD get_arg
    .WORD get_event
    .WORD event_return
    .WORD free_page_span
    .WORD print_fletch16
    .WORD rand_8
    .WORD set_direct_timer
    .WORD dbg_byte
    .WORD vfs_next_block
    .WORD vfs_ide_write_block
