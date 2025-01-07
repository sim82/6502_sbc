struct Vm {
    variables: [u8; 256],
    code: [u8; 256],
    ip: usize,
}

const OP_BREAK: u8 = 0x00;
const OP_STORE_IMMEDIATE: u8 = 0x02;
const OP_ADD_IMMEDIATE: u8 = 0x04;
const OP_PRINT: u8 = 0x08;
const OP_BNE: u8 = 0x10;
const OP_BEQ: u8 = 0x12;
const OP_BMI: u8 = 0x14;
const OP_BPL: u8 = 0x16;

impl Vm {
    pub fn new(code_init: &[u8]) -> Vm {
        let mut code = [0u8; 256];
        code[..(code_init.len())].copy_from_slice(code_init);
        Vm {
            variables: [0u8; 256],
            code,
            ip: 0,
        }
    }
    pub fn run(&mut self) {
        loop {
            let instr = self.code[self.ip];
            println!("trace: {}: {}", self.ip, instr as usize);
            let inc = match instr {
                OP_STORE_IMMEDIATE => {
                    let i = self.code[self.ip + 1] as usize;
                    let v = self.code[self.ip + 2];
                    self.variables[i] = v;
                    3
                }
                OP_ADD_IMMEDIATE => {
                    let i = self.code[self.ip + 1] as usize;
                    let v = self.code[self.ip + 2];
                    self.variables[i] = self.variables[i].wrapping_add(v);
                    3
                }
                OP_BNE => {
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
                OP_PRINT => {
                    let i = self.code[self.ip + 1] as usize;
                    let v = self.variables[i] as usize;
                    println!("print {}: {}", i, v);
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
            OP_BNE,
            00,
            01,
            06,
            OP_BREAK,
        ];
        let mut vm = Vm::new(&code);
        vm.run();
    }
}
