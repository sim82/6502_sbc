.include "std.inc"

.import uart_init, putc, put_newline, fpurge, fputc, fgetc, print_hex16, print_hex8
.ZEROPAGE
.res $80
status: .res $1 ; bootstrap status from stage1 bootloader
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
lba_low: .res $1
; lba_mid: .res $1
; lba_high: .re $1


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

    lda status
    beq @skip_status_message
    print_string msg_bootstrapped
    lda status
    cmp #$1
    beq @status_uart
    cmp #$2
    beq @status_ide

@status_uart:
    lda #<msg_uart
    ldx #>msg_uart
    jmp @print_status
@status_ide:
    lda #<msg_ide
    ldx #>msg_ide
@print_status:
    jsr print_message
@skip_status_message:

    jsr load_uart
    ; jsr load_ide
; delete windmill
    lda #$08
    jsr putc
    print_string msg_done
    jsr delay
    jmp (receive_pos) ; jump to loaded code

load_uart:
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
    rts


load_ide:
    print_string msg_loading_ide
    lda #$71
    sta lba_low
    
    jsr wait_ready

    lda #$00
    sta io_addrl
    sta IO_IDE_LBA_MID
    sta IO_IDE_LBA_HIGH
    lda #$01
    sta IO_IDE_SIZE
    lda #$e0
    sta IO_IDE_DRIVE_HEAD
    ; lda #$e0 such luck...
    sta io_addrh

    print_string msg_loading
@load_page_loop:
    jsr print_windmill
    ; issue read command to ide
    lda lba_low
    sta IO_IDE_LBA_LOW
    ; jsr print_hex8
    ; lda io_addrh
    ; jsr print_hex8
    ; jsr put_newline

    lda #$20
    sta IO_IDE_CMD

    jsr wait_drq
    ; this loop is running two times per (512 byte) io block:
    ; 1) read the first 256 bytes to IO_ADDR
    ; 2) then inc IO_ADDR high, and if lowest bit is set (i.e. it is the upper half of the current 
    ;    512 byte io block) run the loop again for the next 256 bytes
    ; 3) after the second run (when after IO_ADDR inc the low bit is 0), increase LBA_LOW address and start next io block
    ;
    ; Precondition: RECEIVE_POS must be 512 byte aligned!
    ldy #$00
@loop_full_page:
    lda IO_IDE_DATA_LOW
    sta (io_addr), y
    iny
    lda IO_IDE_DATA_HIGH
    sta (io_addr), y
    iny
    bne @loop_full_page	; end on y wrap around
    inc io_addrh
    lda io_addrh
    ; check if we reached the end of the e000 - fe00 range
    cmp #$fe
    beq @done
    ; check if we are in the middle of 512 byte block
    ror
    bcs @loop_full_page

    ; advance LBA_LOW	
    inc lba_low
    bne @load_page_loop ; always true, X never 0

@done:
    lda #$e0
    sta receive_posh
    lda #$00
    sta receive_posl
    rts

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

wait_ready:
	; inlined to reduce code size
@wait_ready_loop:
	lda $fe27
	; check BSY bit (bit 7)
	rol
	bcs @wait_ready_loop
    rts

wait_drq:
    lda $fe27
    and #%00001000
    beq wait_drq
    rts
    
delay:
; simple delay loop before jumping to loaded code, to ensure uart transmission is done
    ldx #$ff
    ldy #$ff
@delay_loop_y:
    dey
    bne @delay_loop_y
    dex
    stx IO_GPIO0
    bne @delay_loop_y
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
    .byte "=== Stage2 Bootloader v0.1", $0a, $0d, $00
msg_bootstrapped:
    .byte "Bootstrapped via ", $00
msg_uart:
    .byte "UART", $0a, $0d, $00
msg_ide:
    .byte "IDE", $0a, $0d, $00
msg_loading_uart:
    .byte "Loading via UART...", $0a, $0d, $00
msg_loading_ide:
    .byte "Loading via IDE...", $0a, $0d, $00
msg_position:
    .byte "Load address: $", $00
msg_size:
    .byte ", Size: $", $00
msg_loading:
    .byte "Loading  ", $00
msg_done:
    .byte "Done.", $0a, $0d, $00
.end
