.include "std.inc"

.import uart_init, putc, put_newline, fpurge, fputc, fgetc, print_hex16
.ZEROPAGE
.res $80
zp_ptr: .res $2
io_addr:
io_addrl: .res $1
io_addrh: .res $1
receive_pos:
receive_posl: .res $1
receive_posh: .res $1
receive_size:
receive_sizel: .res $1
receive_sizeh: .res $1

.macro print_string msg
    lda #<msg
    ldx #>msg
    jsr print_message
.endmacro

.code
    ; reset undefined processor state
    ldx #$ff
    txs
    cld
    sei ; disable interrupts, because irq vector gets set up before the client code is initialized -> client code must enable interrupts itself if desired

    jsr uart_init
    jsr put_newline
    print_string msg_greeting

    jsr fpurge
    print_string msg_loading_uart
    ;;;;;;;;;;;;;;;;;;;;;
    ; send filename 
@filename_loop:
	lda filename, y
	iny
	jsr fputc
	bne @filename_loop
    ;;;;;;;;;;;;;;;;;;;;;
    ; read file metadata

	jsr fgetc	; read target address low byte
	sta receive_posl
	sta io_addrl
	jsr fgetc	; and high byte
	sta receive_posh	
	sta io_addrh
    jsr fgetc	; read file size low byte
    sta receive_sizel
	jsr fgetc	; and high byte
	sta receive_sizeh

    print_string msg_position
    lda io_addrl
    ldx io_addrh
    jsr print_hex16

    print_string msg_size
    lda receive_sizel
    ldx receive_sizeh
    jsr print_hex16
    jsr put_newline
    print_string msg_loading


@load_page_loop:
    lda receive_sizeh
    beq @done_loading
    jsr print_windmill
    lda #'b'
    jsr fputc
    ldy #$00

@load_full_page:
    jsr fgetc
    sta (io_addr), y
    iny
    bne @load_full_page
    dec receive_sizeh
    inc io_addrh
    jmp @load_page_loop

@done_loading:
; delete windmill
    lda #$08
    jsr putc
    print_string msg_done

; simple delay loop before jumping to loaded code, to ensure uart transmission is done
    ldx #$ff
    ldy #$ff
@delay_loop_y:
    dey
    bne @delay_loop_y
    dex
    stx IO_GPIO0
    bne @delay_loop_y
    jmp (receive_pos) ; jump to loaded code

; low in a, high in x,
print_message:
	sta zp_ptr
	stx zp_ptr + 1
	tya
	pha
	ldy #$00
@loop:
	lda (zp_ptr), y
	beq @end
	jsr putc
	iny
	jmp @loop
@end:
	pla
	tay
	rts

print_windmill:
    lda #$08 ; backspace
    jsr putc
    lda io_addrh
    ror
    ror
    and #$03
    tax
    lda windmill_chars, x
    jsr putc
    ldy #$00
    rts

windmill_chars:
	.byte $5c, "|/-"
filename:
 	.byte "o.b", $00

msg_greeting:
 	.byte "Hello, World!", $0a, $0d, $00
msg_loading_uart:
 	.byte "Loading via UART...", $0a, $0d, $00
msg_position:
 	.byte "Load address: $", $00
msg_size:
 	.byte ", Size: $", $00
msg_loading:
 	.byte "Loading  ", $00
msg_done:
 	.byte "Done.", $0a, $0d, $00
.end