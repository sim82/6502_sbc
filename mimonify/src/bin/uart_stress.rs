use anyhow::{anyhow, Result};
use byteorder::{LittleEndian, ReadBytesExt, WriteBytesExt};
use mimonify::guess_program_space;
use serial::prelude::*;
use std::{
    io::{prelude::*, stdout},
    path::{Path, PathBuf},
    time::Duration,
};

fn main() {
    let mut port = serial::open(
        // "/dev/serial/by-id/usb-Raspberry_Pi_Debug_Probe__CMSIS-DAP__E6633861A37D6E38-if01",
        "/dev/serial/by-id/usb-WCH.CN_USB_Quad_Serial_BC04A6ABCD-if00",
    )
    .unwrap();
    port.reconfigure(&|settings| {
        settings.set_baud_rate(serial::BaudOther(230400)).unwrap();
        settings.set_char_size(serial::Bits8);
        settings.set_parity(serial::ParityNone);
        settings.set_stop_bits(serial::Stop1);
        settings.set_flow_control(serial::FlowNone);
        Ok(())
    })
    .unwrap();
    port.set_timeout(Duration::from_secs(5)).unwrap();
    let mut x: u64 = 0;
    loop {
        let send = x as u8;

        // println!("send {}", send);
        port.write_u8(send).unwrap();
        let recv = port.read_u8().unwrap();
        if recv != (x as u8) {
            println!("error at byte {}: {} vs. {}", x, send, recv);
            loop {
                if let Err(_) = port.read_u8() {
                    println!("read to timeout");
                    break;
                }
            }
        }
        x += 1;
        if x % 10000 == 0 {
            println!("{}", x);
        }
    }
}
