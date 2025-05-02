.IMPORT uart_init, print_hex8, put_newline, getc, putc

; .INCLUDE "std.inc"
.INCLUDE "os.inc"


.CODE

	sei

reset:
	; jsr uart_init

@loop:
	jsr os_getc
	jsr os_putc
	jmp @loop

