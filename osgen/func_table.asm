.IMPORT alloc_page_span, getc_blocking, putc, file_open_raw, fgetc_buf, print_dec, put_newline, print_message, get_argn, get_arg, get_event, event_return
.EXPORT os_func_table

os_func_table:
    .WORD alloc_page_span
    .WORD getc_blocking
    .WORD putc
    .WORD file_open_raw
    .WORD fgetc_buf
    .WORD print_dec
    .WORD put_newline
    .WORD print_message
    .WORD get_argn
    .WORD get_arg
    .WORD get_event
    .WORD event_return
