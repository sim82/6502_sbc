

.INCLUDE "std.inc"
.INCLUDE "os.inc"

ZP = $80
NUM_OPEN =                ZP + $00
STACK_PTR =               ZP + $01
SEL_OPEN_FIELD =          ZP + $02
MIN =                     ZP + $03
TMP_OPEN_FIELD =          ZP + $04
CAND_L =                  ZP + $05
CAND_H =                  ZP + $06
CUR_NUM =                 ZP + $07


STACK_SIZE = 9 * 9
CAND_L_UNDEF = %00000000
CAND_H_UNDEF = %10000000
NUM_UNDEF = $0
FIELD_UNDEF = $ff

.CODE
        jsr init_stack
        jsr load_input
        jsr solve
        rts

init_stack:
        ldx #0
        stx STACK_PTR
@stack_init_loop:
        lda #CAND_L_UNDEF
        sta cand_l_stack, x
        
        lda #CAND_H_UNDEF
        sta cand_h_stack, x

        lda #NUM_UNDEF
        sta num_stack, x

        lda #FIELD_UNDEF
        sta field_stack, x

        inx
        cpx #STACK_SIZE
        bne @stack_init_loop
        rts

load_input:
        ; pseudo input, works with test data in open / free / field
        lda #58
        sta NUM_OPEN ; test data
        rts
        
solve:
        ldx STACK_PTR
        lda cand_h_stack, x
        cmp #CAND_H_UNDEF
        bne @clear_current_field
        ; no field selected -> select next best open field
        jsr select_open_field
        jsr remove_open

        jmp @select_next_best_candidate
@clear_current_field:
        ; field is currently selected contains previous candidate -> cleanup
        jsr clear_field

@select_next_best_candidate:
        ; select next candidate for current field and solve recursively
        jsr select_candidate

        ; OPT: a already correct from selecte_candidate
        ldx STACK_PTR
        lda num_stack, x
        ; ldx #0
        ; jsr os_print_dec
        ; jsr os_putnl
        ; rts
        cmp #9
        bcs @unsolvable
        ; test next candidate
        jsr apply_candidate
        jsr set_field

        ; push new empty stack frame (init 'recursion')
        ldx STACK_PTR
        inx
        stx STACK_PTR
        lda #CAND_L_UNDEF
        sta cand_l_stack, x
        lda #CAND_H_UNDEF
        sta cand_h_stack, x
        lda #0
        sta num_stack, x
        lda #FIELD_UNDEF
        sta field_stack, x
        ; end of loop
        jmp solve

@unsolvable:
        ; none of the candidates for the current field was solvable -> backtrack
        jsr push_open
        dec STACK_PTR
        ; end of loop
        jmp solve
        rts

select_open_field:
        lda #$ff
        sta SEL_OPEN_FIELD
        sta MIN
        lda #00
        sta TMP_OPEN_FIELD

@loop:
        lda TMP_OPEN_FIELD
        cmp NUM_OPEN
        bcs @end
        jsr candidates_for_tmp_field
        ldx CAND_L
        lda count_ones, x
        ldx CAND_H
        clc
        adc count_ones, x


        cmp MIN
        bcs @not_better
        sta MIN
        lda TMP_OPEN_FIELD
        sta SEL_OPEN_FIELD
        ldx STACK_PTR
        lda CAND_L
        sta cand_l_stack, x
        lda CAND_H
        sta cand_h_stack, x

        lda MIN
        cmp #1
        beq @end
@not_better:
        inc TMP_OPEN_FIELD
        jmp @loop

@end:
        lda SEL_OPEN_FIELD
        ; pha
        ; ldx #00
        ; jsr os_print_dec
        ; jsr os_putnl
        ; pla
        ; jmp endless_loop
        cmp #$ff
        beq sel_open_field_error

        rts

sel_open_field_error:
	lda #<msg_sel_open_field_failed
	ldx #>msg_sel_open_field_failed
	jsr os_print_string
	jsr os_putnl
        jmp endless_loop
        
candidates_for_tmp_field:
        ldy TMP_OPEN_FIELD
        ldx open, y

        ldy f2h, x
        lda h_free_l, y
        ldy f2v, x
        and v_free_l, y
        ldy f2b, x
        and b_free_l, y
        sta CAND_L

        ldy f2h, x
        lda h_free_h, y
        ldy f2v, x
        and v_free_h, y
        ldy f2b, x
        and b_free_h, y
        sta CAND_H
        rts

remove_open:
        ldx SEL_OPEN_FIELD
        ldy STACK_PTR
        lda open, x
        sta field_stack, y
        dec NUM_OPEN
        ldy NUM_OPEN
        lda open, y
        sta open, x
        rts

push_open:
        ldx STACK_PTR
        lda field_stack, x
        ldx NUM_OPEN
        sta open, x
        inx
        stx NUM_OPEN
        rts

select_candidate:
        ldx STACK_PTR
        lda cand_l_stack, x
        beq @test_high
        tay
        lda trailing_zeros, y
        sta num_stack, x
        rts

@test_high:
        lda cand_h_stack, x
        tay
        lda trailing_zeros, y
        clc
        adc #8
        sta num_stack, x
        rts

.MACRO reset_kernel lu, free
        ldx lu, y
        lda free, x
        ldx CUR_NUM
        and reset_mask, x
        ldx lu, y
        sta free, x
.ENDMACRO
set_field:
        ldx STACK_PTR
        lda num_stack, x
        cmp #8
        bcs @high
        ; low byte
        sta CUR_NUM
        ldy field_stack, x

        reset_kernel f2h, h_free_l
        reset_kernel f2v, v_free_l
        reset_kernel f2b, b_free_l

        jmp @end
        ; ldx fh2, y
        ; lda h_free_l, x
        ; ldx CUR_NUM
        ; and reset_mask, x
        ; ldx fh2, y
        ; sta h_free_l, x

@high:
        clc
        sbc #8
        sta CUR_NUM
        ldy field_stack, x
        ;high byte
        reset_kernel f2h, h_free_h
        reset_kernel f2v, v_free_h
        reset_kernel f2b, b_free_h
        
        ; ldy field_stack, y
        
@end:
        ldx STACK_PTR
        lda num_stack, x
        sta fields, y
        
        rts

.MACRO set_kernel lu, free
        ldx lu, y
        lda free, x
        ldx CUR_NUM
        ora set_mask, x
        ldx lu, y
        sta free, x
.ENDMACRO

clear_field:
        ldx STACK_PTR
        lda num_stack, x
        cmp #8
        bcs @high
        ; low byte
        sta CUR_NUM
        ldy field_stack, x

        set_kernel f2h, h_free_l
        set_kernel f2v, v_free_l
        set_kernel f2b, b_free_l

        jmp @end
        ; ldx fh2, y
        ; lda h_free_l, x
        ; ldx CUR_NUM
        ; and reset_mask, x
        ; ldx fh2, y
        ; sta h_free_l, x

@high:
        clc
        sbc #8
        sta CUR_NUM
        ldy field_stack, x
        ;high byte
        set_kernel f2h, h_free_h
        set_kernel f2v, v_free_h
        set_kernel f2b, b_free_h
        
        ; ldy field_stack, y
        
@end:
        lda FIELD_UNDEF
        sta fields, y
        
        rts


apply_candidate:
        rts


endless_loop:
        jmp endless_loop
        
msg_sel_open_field_failed:
.byte        "error: select open field", $00

; .BSS FIXME: BSS does not work for size != 256
cand_l_stack:
.RES STACK_SIZE

cand_h_stack:
.RES STACK_SIZE

num_stack:
.RES STACK_SIZE

field_stack:
.RES STACK_SIZE

.RODATA
; RW state: deliver initial values in RODATA for now
fields:
.byte        255,255,255,255,255,255,3,255,4,5,1,255,255
.byte        255,7,255,255,6,255,3,255,255,2,5,255,255
.byte        255,255,255,255,255,0,255,255,1,255,255
.byte        255,2,8,255,255,255,255,255,4,0,255,255,255
.byte        255,255,8,2,255,255,255,1,255,255,255,255
.byte        255,8,255,255,255,255,255,6,255,255,255,255
.byte        5,255,255,2,255,7,255

open:
.byte        0,1,2,3,4,5,7,11,12,13,15,16,18,20
.byte        21,24,25,26,27,28,29,30,32,33,35,36
.byte        37,40,41,42,43,44,47,48,49,50,51,54
.byte        55,56,58,59,60,61,62,64,65,66,67,68
.byte        70,71,72,73,75,76,78,80,80,80,80,80
.byte        80,80,80,80,80,80,80,80,80,80,80,80
.byte        80,80,80,80,80,80,80

h_free_l:
.byte        %11001111, %11110100, %11011011, %11111101, %11111010, %01011011, %10110111, %01111101, %10101011
h_free_h:
.byte        %00000000, %00000001, %00000001, %00000000, %00000001, %00000001, %00000001, %00000000, %00000001
v_free_l:
.byte        %11100111, %00011101, %11010011, %11111100, %11111011, %11101010, %11111101, %10111111, %01011011
v_free_h:
.byte        %00000001, %00000001, %00000001, %00000001, %00000000, %00000000, %00000001, %00000000, %00000001
b_free_l:
.byte        %11010101, %01011011, %10100111, %11101010, %11111110, %11111001, %11011111, %11111001, %00111111
b_free_h:
.byte        %00000001, %00000001, %00000001, %00000001, %00000000, %00000000, %00000000, %00000001, %00000001


; RO lookup tables
f2h:
.byte        0,1,2,3,4,5,6,7,8
.byte        0,1,2,3,4,5,6,7,8
.byte        0,1,2,3,4,5,6,7,8
.byte        0,1,2,3,4,5,6,7,8
.byte        0,1,2,3,4,5,6,7,8
.byte        0,1,2,3,4,5,6,7,8
.byte        0,1,2,3,4,5,6,7,8
.byte        0,1,2,3,4,5,6,7,8
.byte        0,1,2,3,4,5,6,7,8


f2v:
.byte        0,0,0,0,0,0,0,0,0
.byte        1,1,1,1,1,1,1,1,1
.byte        2,2,2,2,2,2,2,2,2
.byte        3,3,3,3,3,3,3,3,3
.byte        4,4,4,4,4,4,4,4,4
.byte        5,5,5,5,5,5,5,5,5
.byte        6,6,6,6,6,6,6,6,6
.byte        7,7,7,7,7,7,7,7,7
.byte        8,8,8,8,8,8,8,8,8

f2b:
.byte        0,0,0,1,1,1,2,2,2
.byte        0,0,0,1,1,1,2,2,2
.byte        0,0,0,1,1,1,2,2,2
.byte        3,3,3,4,4,4,5,5,5
.byte        3,3,3,4,4,4,5,5,5
.byte        3,3,3,4,4,4,5,5,5
.byte        6,6,6,7,7,7,8,8,8
.byte        6,6,6,7,7,7,8,8,8
.byte        6,6,6,7,7,7,8,8,8

count_ones:
.byte        0,1,1,2,1,2,2,3,1,2,2,3,2,3,3,4
.byte        1,2,2,3,2,3,3,4,2,3,3,4,3,4,4,5
.byte        1,2,2,3,2,3,3,4,2,3,3,4,3,4,4,5
.byte        2,3,3,4,3,4,4,5,3,4,4,5,4,5,5,6
.byte        1,2,2,3,2,3,3,4,2,3,3,4,3,4,4,5
.byte        2,3,3,4,3,4,4,5,3,4,4,5,4,5,5,6
.byte        2,3,3,4,3,4,4,5,3,4,4,5,4,5,5,6
.byte        3,4,4,5,4,5,5,6,4,5,5,6,5,6,6,7
.byte        1,2,2,3,2,3,3,4,2,3,3,4,3,4,4,5
.byte        2,3,3,4,3,4,4,5,3,4,4,5,4,5,5,6
.byte        2,3,3,4,3,4,4,5,3,4,4,5,4,5,5,6
.byte        3,4,4,5,4,5,5,6,4,5,5,6,5,6,6,7
.byte        2,3,3,4,3,4,4,5,3,4,4,5,4,5,5,6
.byte        3,4,4,5,4,5,5,6,4,5,5,6,5,6,6,7
.byte        3,4,4,5,4,5,5,6,4,5,5,6,5,6,6,7
.byte        4,5,5,6,5,6,6,7,5,6,6,7,6,7,7,8


trailing_zeros:
.byte        4,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0
.byte        5,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0
.byte        4,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0
.byte        6,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0
.byte        4,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0
.byte        5,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0
.byte        4,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0
.byte        7,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0
.byte        4,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0
.byte        5,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0
.byte        4,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0
.byte        6,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0
.byte        4,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0
.byte        5,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0
.byte        4,0,1,0,2,0,1,0,3,0,1,0,2,0,1,0

set_mask:
.byte        %00000001
.byte        %00000010
.byte        %00000100
.byte        %00001000
.byte        %00010000
.byte        %00100000
.byte        %01000000
.byte        %10000000

reset_mask:
.byte        %11111110
.byte        %11111101
.byte        %11111011
.byte        %11110111
.byte        %11101111
.byte        %11011111
.byte        %10111111
.byte        %01111111

open_initial:
.byte         0, 1, 2, 3, 4, 5, 6, 7, 8, 9
.byte        10,11,12,13,14,15,16,17,18,19
.byte        20,21,22,23,24,25,26,27,28,29
.byte        30,31,32,33,34,35,36,37,38,39
.byte        40,41,42,43,44,45,46,47,48,49
.byte        50,51,52,53,54,55,56,57,58,59
.byte        60,61,62,63,64,65,66,67,68,69
.byte        70,71,72,73,74,75,76,77,78,79
.byte        80

