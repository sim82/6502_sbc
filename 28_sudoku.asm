

.INCLUDE "std.inc"
.INCLUDE "os.inc"

NUM_OPEN = $80
STACK_PTR = NUM_OPEN + 1

STACK_SIZE = 9 * 9
CAND_L_UND = %00000000
CAND_H_UND = %10000000
NUM_UND = $0
FIELD_UND = $ff

.CODE
        jsr init_stack
        jsr load_input
        jst solve
        rts

init_stack:
        ldx #0
        stx STACK_PTR
@stack_init_loop:
        lda #CAND_L_UND
        sta cand_l_stack, x
        
        lda #CAND_H_UND
        sta cand_h_stack, x

        lda #NUM_UND
        sta num_stack, x

        lda #FIELD_UND
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
        cmp #CAND_H_UND
        bne @clear_current_field
        ; no field selected -> select next best open field

        jmp @select_next_best_candidate
@clear_current_field:
        ; field is currently selected contains previous candidate -> cleanup
        jsr clear_field

@select_next_best_candidate:
        ; select next candidate for current field and solve recursively
        jsr select_candidate
        ldx STACK_PTR
        lda num_stack, x
        cmp #9
        bcs @unsolvable
        ; test next candidate
        jsr apply_candidate
        jsr set_field

        ; push new empty stack frame (init 'recursion')
        ldx STACK_PTR
        inx
        stx STACK_PTR
        lda #CAND_L_UND
        sta cand_l_stack, x
        lda #CAND_H_UND
        sta cand_h_stack, x
        lda #0
        sta num_stack, x
        lda #FIELD_UND
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

clear_field:
        rts

select_candidate:
        rts


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
