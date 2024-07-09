use byteorder::{LittleEndian, ReadBytesExt, WriteBytesExt};
use mimonify::guess_program_space;
use serial::prelude::*;
use std::{
    io::prelude::*,
    path::{Path, PathBuf},
    time::Duration,
};

struct OpenFile {
    data: Vec<u8>,
    start: u16,
    end: u16,
    ptr: u16,
}

impl OpenFile {
    pub fn read_from<F: AsRef<Path>>(name: F) -> OpenFile {
        let mut filename = PathBuf::new();
        filename.push("disk");
        filename.push(name);
        let data = std::fs::read(filename).unwrap();
        let (start, end) = guess_program_space(&data);
        OpenFile {
            data,
            start: start as u16,
            end: end as u16,
            ptr: start as u16,
        }
        // filena
        // std::fs::read()
    }
}
fn main() {
    let mut port = serial::open(
        "/dev/serial/by-id/usb-Raspberry_Pi_Debug_Probe__CMSIS-DAP__E6633861A3387C2C-if01",
    )
    .unwrap();
    port.reconfigure(&|settings| {
        settings.set_baud_rate(serial::Baud38400).unwrap();
        settings.set_char_size(serial::Bits8);
        settings.set_parity(serial::ParityNone);
        settings.set_stop_bits(serial::Stop1);
        settings.set_flow_control(serial::FlowNone);
        Ok(())
    })
    .unwrap();
    loop {
        let mut buf = [0u8];
        // let Ok(1) = port.read(&mut buf) else {
        //     continue;
        // };
        let Ok(c) = port.read_u8() else {
            continue;
        };

        println!("{:x}", c);
        if c == b'o' {
            open_file(&mut port);
        }
    }
}
fn open_file<T: SerialPort>(port: &mut T) {
    println!("open file");
    let mut filename = String::new();
    loop {
        let Ok(c) = port.read_u8() else {
            continue;
        };
        println!("fn: {:x}", c);
        if c != 0x0 {
            filename.push(c.into());
        } else {
            break;
        }
    }
    println!("open file: {}", filename);
    let file = OpenFile::read_from(filename);
    serve_file(port, file);
}
fn serve_file<T: SerialPort>(port: &mut T, file: OpenFile) {
    println!("serve: {:x} - {:x}", file.start, file.end);
    let size = file.end - file.start;
    port.write_u16::<LittleEndian>(file.start);
    port.write_u16::<LittleEndian>(size);
    let start = file.start as usize;
    let end = file.end as usize;

    let data = &file.data[start..end];

    for chunk in data.chunks(256) {
        println!("chunk: {}", chunk.len());
        // for c in chunk {
        //     port.write_u8(*c);
        // }
        port.write_all(chunk).unwrap();
        port.flush();
        // std::thread::sleep(Duration::from_secs(1))
    }
    // loop {}
}
