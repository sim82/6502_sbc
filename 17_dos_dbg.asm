.include "std.inc"
.import print_dec, putc
.export dbg_byte

dbg_byte:
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
