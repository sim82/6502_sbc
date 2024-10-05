.IMPORT uart_init, print_hex8, put_newline, getc, putc

.INCLUDE "std.inc"


.CODE


reset:
	jsr uart_init

@loop:
	jsr getc
	jsr putc
	jmp @loop

