.include "std.inc"
.import print_dec, putc, print_hex8
.export dbg_byte

dbg_byte_dec:
        pha
        phx
        phy
        lda ARG0
        ldx #0
        jsr print_dec

        lda #' '
        jsr putc
        ply
        plx
        pla
        rts


dbg_byte:
dbg_byte_hex:
        pha
        lda #'0'
        jsr putc
        lda #'x'
        jsr putc
        lda ARG0
        jsr print_hex8
        lda #' '
        jsr putc
        pla
        rts


dbg_byte_bin:
        pha
        lda #'0'
        jsr putc
        lda #'b'
        jsr putc
        lda ARG0
        jsr print_bin8
        lda #' '
        jsr putc
        pla
        rts

print_bin8:
        sta NUM2
        phy
        ldy #8
        ; ldx #%10000000
@loop:
        asl NUM2
        lda #0
        adc #'0'
        jsr putc
        
        dey
        bne @loop
        ply
        rts
        
