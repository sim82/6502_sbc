
INPUT_LINE = $0200				; address of input line
INPUT_LINE_LEN = $50				; capacity of input line
INPUT_LINE_PTR = INPUT_LINE + INPUT_LINE_LEN	; address of current input line ptr 
						; (relative to address of input line)

NEXT_TOKEN_PTR   = INPUT_LINE_PTR + 1
NEXT_TOKEN_END   = NEXT_TOKEN_PTR + 1

RECEIVE_POS = NEXT_TOKEN_END + 1
RECEIVE_SIZE = RECEIVE_POS + 2
IO_FUN = RECEIVE_SIZE + 2

ZP_PTR = $80

IO_ADDR = ZP_PTR + 2
FLETCH_1 = IO_ADDR + 2
FLETCH_2 = FLETCH_1 + 1

IO_BW_END = FLETCH_2 + 1
IO_BW_PTR = IO_BW_END + 1
IO_BW_EOF = IO_BW_PTR + 1

AL = IO_BW_EOF + 1
AH = AL + 1

BL = AH + 1
BH = BL + 1

CL = BH + 1
CH = CL + 1

MON_ADDRL = CH + 1
MON_ADDRH = MON_ADDRL + 1

IO_BUFFER = $0300

.macro set_ptr src
	ldx #<src
	stx ZP_PTR
	ldx #>src
	stx ZP_PTR + 1
.endmacro

.macro dispatch_command cmd_ptr, dest
.local @next
	set_ptr cmd_ptr
	jsr compare_token
	bcc @next
	jsr dest
	jmp @cleanup
@next:
.endmacro

.macro print_message_from_ptr src
	lda #<src
	ldx #>src
	jsr print_message
.endmacro

; store 16bit value (addr) into two bytes of memory at dest
.macro store_address addr, dest
	lda #<addr
	sta dest
	lda #>addr
	sta dest + 1
.endmacro
