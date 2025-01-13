const TRACE: bool = false;

pub struct Vm {
    variables: [u16; 256],
    code: [u8; 256],
    ip: usize,
}

// .WORD op_break			; $00
// .WORD op_store_immediate	; $02
// .WORD op_add_immediate		; $04
// .WORD op_store_immediate16	; $06
// .WORD op_print			; $08
// .WORD $0000			; $0a
// .WORD $0000			; $0c
// .WORD $0000			; $0e
// .WORD op_bne16			; $10
// .WORD op_beq16			; $12
// .WORD op_blt16			; $14
// .WORD op_bge16			; $16
pub mod opcodes {

    pub const OP_BREAK: u8 = 0x00;
    pub const OP_STORE_IMMEDIATE: u8 = 0x02;
    pub const OP_ADD_IMMEDIATE: u8 = 0x04;
    pub const OP_STORE_IMMEDIATE16: u8 = 0x06;
    pub const OP_PRINT: u8 = 0x08;
    pub const OP_BNE16: u8 = 0x10;
    pub const OP_BEQ16: u8 = 0x12;
    pub const OP_BLT16: u8 = 0x14;
    pub const OP_BGE16: u8 = 0x16;
}
use opcodes::*;

impl Vm {
    pub fn new(code_init: &[u8]) -> Vm {
        let mut code = [0u8; 256];
        code[..(code_init.len())].copy_from_slice(code_init);
        Vm {
            variables: [0u16; 256],

            code,
            ip: 0,
        }
    }
    pub fn run(&mut self) {
        loop {
            let instr = self.code[self.ip];
            if TRACE {
                println!("trace: {}: {}", self.ip, instr as usize);
            }
            let inc = match instr {
                OP_STORE_IMMEDIATE => {
                    let i = self.code[self.ip + 1] as usize;
                    let v = self.code[self.ip + 2] as u16;
                    self.variables[i] = v;
                    3
                }
                OP_STORE_IMMEDIATE16 => {
                    let i = self.code[self.ip + 1] as usize;
                    let vlo = self.code[self.ip + 2] as u16;
                    let vhi = self.code[self.ip + 3] as u16;
                    self.variables[i] = vlo | (vhi << 8);
                    4
                }
                OP_ADD_IMMEDIATE => {
                    let i = self.code[self.ip + 1] as usize;
                    let v = self.code[self.ip + 2] as u16;
                    self.variables[i] = self.variables[i].wrapping_add(v);
                    3
                }
                OP_BNE16 => {
                    let a = self.code[self.ip + 1] as usize;
                    let b = self.code[self.ip + 2] as usize;
                    if self.variables[a] != self.variables[b] {
                        let ip = self.code[self.ip + 3] as usize;
                        self.ip = ip;
                        0
                    } else {
                        4
                    }
                }
                OP_BEQ16 => {
                    let a = self.code[self.ip + 1] as usize;
                    let b = self.code[self.ip + 2] as usize;
                    if self.variables[a] != self.variables[b] {
                        let ip = self.code[self.ip + 3] as usize;
                        self.ip = ip;
                        0
                    } else {
                        4
                    }
                }
                OP_BLT16 => {
                    let a = self.code[self.ip + 1] as usize;
                    let b = self.code[self.ip + 2] as usize;
                    if self.variables[a] < self.variables[b] {
                        let ip = self.code[self.ip + 3] as usize;
                        self.ip = ip;
                        0
                    } else {
                        4
                    }
                }

                OP_BGE16 => {
                    let a = self.code[self.ip + 1] as usize;
                    let b = self.code[self.ip + 2] as usize;
                    if self.variables[a] >= self.variables[b] {
                        let ip = self.code[self.ip + 3] as usize;
                        self.ip = ip;
                        0
                    } else {
                        4
                    }
                }

                OP_PRINT => {
                    let i = self.code[self.ip + 1] as usize;
                    let v = self.variables[i] as usize;
                    if TRACE {
                        println!("print {}: {}", i, v);
                    } else {
                        println!("{}", v);
                    }
                    2
                }
                OP_BREAK => {
                    println!("break");
                    break;
                }
                _ => panic!("unhandled opcode {}", instr),
            };
            self.ip += inc;
        }
    }
}

#[cfg(test)]
mod test {
    use super::*;

    #[test]
    fn test_basic_loop() {
        let code = [
            OP_STORE_IMMEDIATE,
            00,
            00,
            OP_STORE_IMMEDIATE,
            01,
            10,
            OP_ADD_IMMEDIATE,
            00,
            01,
            OP_PRINT,
            00,
            OP_BNE16,
            00,
            01,
            06,
            OP_BREAK,
        ];
        let mut vm = Vm::new(&code);
        vm.run();
    }
}
