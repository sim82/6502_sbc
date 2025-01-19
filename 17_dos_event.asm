.export get_event, event_return
.import print_hex16, print_hex8, put_newline, fgetc_buf, putc
.import alloc_page_span, getc_blocking, putc, print_dec, put_newline, print_message, file_open_raw
.import get_argn, get_arg
.include "17_dos.inc"
.code


get_event:
	lda RESIDENT_EVENT
	ldx RESIDENT_EVENTDATA
	rts

event_return:
	sta RESIDENT_RETURN
	rts

