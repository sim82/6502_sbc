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
        "/dev/serial/by-id/usb-WCH.CN_USB_Quad_Serial_BC04A6ABCD-if04",
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
    // port.read
    loop {
        let recv = port.read_u8();
        if recv.is_err() {
            break;
        }
        println!("flush: {:?}", recv);
    }

    port.set_timeout(Duration::from_secs(5)).unwrap();
    let mut x: u64 = 0;
    loop {
        let send = x as u8;

        const N: usize = 4;
        let mut send_buf = [0u8; N];
        send_buf.iter_mut().for_each(|v| {
            *v = x as u8;
            x += 1;
        });
        // for i in 0..4 {
        //     send_buf[i] = x as u8;
        //     x += 1;
        // }
        let mut recv_buf = [0; N];
        // port.write_u8(send).unwrap();
        port.write_all(&send_buf).unwrap();
        // let recv = port.read_u8().unwrap();
        port.read_exact(&mut recv_buf).unwrap();

        // println!("recv {}", recv);
        if recv_buf != send_buf {
            println!("error at byte {}", x);
        }
        // if recv != (x as u8) {
        //     println!("error at byte {}: {} vs. {}", x, send, recv);
        //     // loop {
        //     //     if let Err(_) = port.read_u8() {
        //     //         println!("read to timeout");
        //     //         break;
        //     //     }
        //     // }
        // }
        // x += 1;
        if x % 1000 == 0 {
            println!("{}", x);
        }
    }
}
