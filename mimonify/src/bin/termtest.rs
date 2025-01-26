use anyhow::{anyhow, Result};
use byteorder::{LittleEndian, ReadBytesExt, WriteBytesExt};
use mimonify::guess_program_space;
use serial::{prelude::*, unix::TTYPort, PortSettings};
use std::{
    io::{prelude::*, stdout},
    path::{Path, PathBuf},
    time::Duration,
};

fn main() {
    let dev = match (std::env::args().nth(1)) {
        Some(dev) => dev,
        None => "/dev/pts/7".into(),
    };
    let baud = std::env::args().nth(2).map_or(serial::Baud115200, |v| {
        serial::BaudOther(v.parse::<usize>().unwrap())
    });
    println!("dev: {} baud: {:?}", dev, baud);
    let mut port = serial::open(&dev).unwrap();
    // port.reconfigure(&|settings| {
    //     settings.set_baud_rate(baud).unwrap();
    //     settings.set_char_size(serial::Bits8);
    //     settings.set_parity(serial::ParityNone);
    //     settings.set_stop_bits(serial::Stop1);
    //     settings.set_flow_control(serial::FlowHardware);
    //     Ok(())
    // })
    // .unwrap();
    port.configure(&PortSettings {
        baud_rate: baud,
        char_size: serial::Bits8,
        parity: serial::ParityNone,
        stop_bits: serial::Stop1,
        flow_control: serial::FlowNone,
    })
    .unwrap();
    // loop {
    //     let x = port.read_cts().unwrap();
    //     println!("cts: {:?}", x);
    // }

    port.clear();
    port.setpos(10, 10);
    // port.bold();

    // port.write_u8(0x1b).unwrap();
    // port.write_u8(b'(').unwrap();
    // port.write_u8(b'0').unwrap();
    port.write_u8(0x1b).unwrap();
    port.write_u8(b'(').unwrap();
    port.write_u8(b'0').unwrap();
    // port.write_u8(0x1b).unwrap();
    // port.write_u8(b')').unwrap();
    // port.write_u8(b'B').unwrap();
    for i in 10..=20 {
        port.write_u8(0x70).unwrap();
        // port.down();
    }
    // port.write_all(b')
}

trait Term {
    fn esc(&mut self);
    fn clear(&mut self);
    fn setpos(&mut self, x: i32, y: i32);
    fn down(&mut self);
    fn bold(&mut self);
}

impl Term for TTYPort {
    fn esc(&mut self) {
        self.write_u8(0x1b).unwrap();
        self.write_u8(b'[').unwrap();
    }
    fn clear(&mut self) {
        self.esc();
        self.write_u8(b'2').unwrap();
        self.write_u8(b'J').unwrap();
    }

    fn setpos(&mut self, x: i32, y: i32) {
        self.esc();
        let s = format!("{};{}H", y, x);
        self.write_all(s.as_bytes()).unwrap();
    }
    fn down(&mut self) {
        self.esc();
        self.write_u8(b'1').unwrap();
        self.write_u8(b'B').unwrap();
    }
    fn bold(&mut self) {
        self.esc();
        self.write_all(b"1m").unwrap();
    }
}
