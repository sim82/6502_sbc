OS_EVENT_INIT    = $00
OS_EVENT_KEY     = $01
OS_EVENT_TIMER   = $02

OS_EVENT_RETURN_EXIT           = $00
OS_EVENT_RETURN_KEEP_RESIDENT  = $01

; allocate contiguous span of pages
; a in: number pages
; a out: start page
; set carry on success
.IMPORT os_alloc 

; get character from standard input (uart 0)
; a out: input char
.IMPORT os_getc 

; put character to standard output (uart 0)
; a in: output char
.IMPORT os_putc 

; open file in raw buffered mode on fileio channel (uart 1)
.IMPORT os_fopen 

; read single character from open buffered file
; a out: input char
.IMPORT os_fgetc 

; print 16bit decimal value on standard output
; a in: low byte
; x in: high byte
.IMPORT os_print_dec 

; print newline on standard output
.IMPORT os_putnl 

; print string on standard output
; a in: atring address low
; x in: string address high
.IMPORT os_print_string 

; get number of command args (argc)
.IMPORT os_get_argn 

; get command argument by index (argv[i])
.IMPORT os_get_arg 

; get current event
; a in: event type
; x in: event payload
.IMPORT os_get_event 

; set event return mode (e.g. keep resident)
.IMPORT os_event_return 

; free contiguous span of pages
; a in: start page
.IMPORT os_free 

; print stats of current file io
.IMPORT os_print_fstat 

; return pseudo random number
; a out: random number
.IMPORT os_rand 

; set vector pointer for direct timer (called from irq handler on timer interrupt)
; a in: addr low
; x in: addr high
.IMPORT os_set_direct_timer 

