use std::{ascii::AsciiExt, collections::HashMap};

use lrpar::Span;

use crate::{
    parser::{Block, BlockElement, Statement},
    vm::opcodes::*,
};

use anyhow::Result;
use anyhow::{anyhow, Context};

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
    pub fn generate(&mut self, block: &Block, input: &[u8]) -> Result<()> {
        for element in &block.0 {
            match element {
                BlockElement::Statement(Statement::Assignment {
                    identifier,
                    expression,
                }) => {
                    let target_name = input_get(input, &identifier);
                    let id = self.get_or_define_variable_slot(&target_name);
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
                                return Err(anyhow!("constant out of range: {}", c));
                            }
                        }
                        crate::parser::Expression::Load(_) => {}
                        crate::parser::Expression::Sum { a, b } => match (a.as_ref(), b.as_ref()) {
                            (
                                crate::parser::Expression::Load(a),
                                crate::parser::Expression::Constant(c),
                            ) => {
                                let name_a = input_get(input, a);
                                if name_a == target_name {
                                    self.code.push(OP_ADD_IMMEDIATE);
                                    self.code.push(id as u8);
                                    self.code.push(*c as u8)
                                }
                            }
                            _ => return Err(anyhow!("sum not implemented for {:?} {:?}", a, b)),
                        },
                        crate::parser::Expression::Product { a, b } => {}
                    }
                }
                BlockElement::Statement(Statement::TestCall {
                    function,
                    identifier,
                }) => {
                    self.code.push(OP_PRINT);
                    let name = input_get(input, &identifier);
                    let slot = self.get_variable_slot(&name)?;
                    self.code.push(slot);
                }
                BlockElement::Statement(Statement::If {
                    a,
                    b,
                    operator,
                    if_block,
                }) => {
                    let name_a = input_get(input, a);
                    let name_b = input_get(input, b);
                    let slot_a = self.get_variable_slot(&name_a)?;
                    let slot_b = self.get_variable_slot(&name_b)?;
                    let (opcode, swap) = match operator {
                        crate::parser::Operator::Eq => (OP_BNE16, false),
                        crate::parser::Operator::Neq => (OP_BEQ16, false),
                        crate::parser::Operator::Lt => (OP_BGE16, false),
                        crate::parser::Operator::Leq => (OP_BLT16, true),
                        crate::parser::Operator::Gt => (OP_BGE16, true),
                        crate::parser::Operator::Geq => (OP_BLT16, false),
                    };
                    let (slot_a, slot_b) = if swap {
                        (slot_b, slot_a)
                    } else {
                        (slot_a, slot_b)
                    };
                    self.code.push(opcode);
                    self.code.push(slot_a);
                    self.code.push(slot_b);
                    let offs = self.code.len();
                    self.code.push(0); // placeholder for jump offset
                    self.generate(if_block, input)?;
                    // let dist = self.code.len() - offs;
                    self.code[offs] = self.code.len() as u8;
                }

                BlockElement::Statement(Statement::Goto { target_label }) => {
                    let target_label_name = input_get(input, target_label);
                    let offs = self
                        .label_address
                        .get(&target_label_name)
                        .ok_or(anyhow!("undefined label {}", target_label_name))?;
                    println!("label {}: {}", target_label_name, offs);
                    self.code.push(OP_JMP);
                    self.code.push(*offs as u8);
                }
                BlockElement::Label(label) => {
                    self.label_address
                        .insert(input_get(input, label), self.code.len());
                }
            }
            //
        }
        self.code.push(OP_BREAK);
        Ok(())
    }
    fn get_variable_slot(&self, name: &str) -> Result<u8> {
        Ok(*self
            .variable_slots
            .get(name)
            .ok_or(anyhow!("variable slot not found"))? as u8)
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
