use std::{ascii::AsciiExt, collections::HashMap};

use lrpar::Span;

use crate::{
    parser::{Block, BlockElement, Statement},
    vm::opcodes::*,
};

#[derive(Default)]
pub struct Codegen {
    code: Vec<u8>,
    label_address: HashMap<String, usize>,
    variable_slots: HashMap<String, usize>,
}

fn input_get(input: &[u8], span: &Span) -> String {
    String::from_utf8_lossy(&input[span.start()..span.end()]).to_string()
}
impl Codegen {
    pub fn generate(&mut self, block: &Block, input: &[u8]) {
        for element in &block.0 {
            match element {
                BlockElement::Statement(Statement::Assignment {
                    identifier,
                    expression,
                }) => {
                    let name = input_get(input, &identifier);
                    let id = self.get_or_define_variable_slot(&name);
                    match expression {
                        crate::parser::Expression::Constant(c) => {
                            if *c < 128 && *c > -128 {
                                self.code.push(OP_STORE_IMMEDIATE);
                                self.code.push(id as u8);
                                self.code.push(*c as u8);
                            } else if *c < 32767 && *c > -32767 {
                                self.code.push(OP_STORE_IMMEDIATE16);

                                self.code.push(id as u8);
                                self.code.push(*c as u8);
                                self.code.push((*c >> 8) as u8);
                            } else {
                                panic!("constant out of range: {}", c);
                            }
                        }
                        crate::parser::Expression::Load(_) => {}
                        crate::parser::Expression::Sum { a, b } => {}
                        crate::parser::Expression::Product { a, b } => {}
                    }
                }
                BlockElement::Statement(Statement::TestCall {
                    function,
                    identifier,
                }) => {
                    self.code.push(OP_PRINT);
                    let name = input_get(input, &identifier);
                    let slot = self.get_variable_slot(&name);
                    self.code.push(slot);
                }
                BlockElement::Statement(Statement::If {
                    a,
                    b,
                    operator,
                    if_block,
                }) => {}

                BlockElement::Statement(Statement::Goto { target_label }) => {}
                BlockElement::Label(label) => {
                    self.label_address
                        .insert(input_get(input, label), self.code.len());
                }
            }
            //
        }
        self.code.push(OP_BREAK);
    }
    fn get_variable_slot(&self, name: &str) -> u8 {
        *self
            .variable_slots
            .get(name)
            .expect("variable slot not found") as u8
    }
    fn get_or_define_variable_slot(&mut self, name: &str) -> u8 {
        let id = self.variable_slots.len();
        match self.variable_slots.entry(name.to_string()) {
            std::collections::hash_map::Entry::Occupied(e) => *e.get() as u8,
            std::collections::hash_map::Entry::Vacant(e) => {
                e.insert(id);
                id as u8
            }
        }
        // *self
        //     .variable_slots
        //     .get(name)
        //     .expect("variable slot not found") as u8
    }

    pub fn get_code(&self) -> &[u8] {
        &self.code
    }
}
