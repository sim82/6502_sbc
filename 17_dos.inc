
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

IO_BUFFER = $0300
