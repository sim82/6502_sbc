use anyhow::{anyhow, Result};
use byteorder::{LittleEndian, ReadBytesExt, WriteBytesExt};
use mimonify::guess_program_space;
use serial::{prelude::*, PortSettings};
use std::{
    io::{prelude::*, stdout},
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
    pub fn read_from<F: AsRef<Path>>(name: F) -> Result<OpenFile> {
        let mut filename = PathBuf::new();
        filename.push("disk");
        filename.push(name);
        let data = std::fs::read(&filename)?;
        let (start, end) = guess_program_space(&data);
        println!(
            "open file: {:?}, guessed program space: {:x} - {:x}",
            filename, start, end
        );
        Ok(OpenFile {
            data,
            start: start as u16,
            end: end as u16,
            ptr: start as u16,
        })
        // filena
        // std::fs::read()
    }
}
fn main() {
    let dev = match (std::env::args().nth(1)) {
        Some(dev) => dev,
        None => "/dev/serial/by-id/usb-Raspberry_Pi_Debug_Probe__CMSIS-DAP__E6633861A3387C2C-if01"
            .into(),
    };
    let baud = std::env::args().nth(2).map_or(serial::Baud38400, |v| {
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
    loop {
        let mut buf = [0u8];
        // let Ok(1) = port.read(&mut buf) else {
        //     continue;
        // };
        let Ok(c) = port.read_u8() else {
            continue;
        };

        // println!("{:x}", c);
        let res = if c == b'o' {
            open_file(&mut port, false, false)
        } else if c == b'r' {
            open_file(&mut port, true, false)
        } else if c == b'w' {
            open_file(&mut port, true, true)
        } else if c == b'2' {
            open_stage2_file(&mut port)
        } else {
            println!("unexpected: {:x} '{}'", c, c as char);
            Ok(())
        };
        match res {
            Ok(_) => (),
            Err(e) => println!("error: {:?}", e),
        }
    }
}
fn open_file<T: SerialPort>(port: &mut T, raw: bool, wide: bool) -> Result<()> {
    port.set_timeout(Duration::from_secs(5)).unwrap();
    let mode = if raw { "raw" } else { "image" };
    // println!("open file {}", mode);
    let mut filename = String::new();
    loop {
        // let Ok(c) = port.read_u8() else {
        //     continue;
        // };
        let c = port.read_u8()?;
        // println!("fn: {:x} '{}'", c, c as char);
        if c != 0x0 {
            filename.push(c.into());
        } else {
            break;
        }
    }
    // println!("open file: {}", filename);
    match OpenFile::read_from(filename) {
        Ok(file) => serve_file(port, file, raw, wide, false)?,
        Err(e) => {
            println!("error: {:?}. abort.", e);
            port.write_u16::<LittleEndian>(0xffff)?;
            if !raw {
                port.write_u16::<LittleEndian>(0xffff)?;
            }
        }
    }
    Ok(())
}

fn open_stage2_file<T: SerialPort>(port: &mut T) -> Result<()> {
    port.set_timeout(Duration::from_secs(5)).unwrap();
    port.write_u8(0x54)?;
    port.write_u8(0x46)?;
    match OpenFile::read_from(".2") {
        Ok(mut file) => {
            // the stage 1 bootloader is extremely simple so it has some special needs wrt. to what we feed it.
            // isolate as much complexity as possible on the server side.
            if file.start != 0x1000 {
                println!(".2 file expected to start at 0x1000");
                port.write_u16::<LittleEndian>(0xffff)?;
                return Ok(());
            }
            if file.end > 0x2000 {
                println!(".2 file too big: {:x}-{:x}", file.start, file.end);
                port.write_u16::<LittleEndian>(0xffff)?;
                return Ok(());
            }
            if file.end != 0x2000 {
                println!("adjust .2 file end {:x} -> 0x2000", file.end);
                file.data.resize(0x2000, 0x0);
                file.end = 0x2000;
            }
            serve_file(port, file, false, false, true)?;
        }
        Err(e) => {
            println!("error: {:?}. abort.", e);
            port.write_u16::<LittleEndian>(0xffff)?;
        }
    }
    Ok(())
}

// TODO: handling of the different modes is getting ridiculous... refactor this!
fn serve_file<T: SerialPort>(
    port: &mut T,
    file: OpenFile,
    raw: bool,
    wide: bool,
    no_header: bool,
) -> Result<()> {
    let mut sum1 = 0u8;
    let mut sum2 = 0u8;

    let size;
    let data;
    if !raw {
        if !no_header {
            port.write_u16::<LittleEndian>(file.start)?;
        }
        size = file.end - file.start;
        let start = file.start as usize;
        let end = file.end as usize;

        data = &file.data[start..end];

        println!(
            "serve binary: {:x} - {:x}, size :{:x}",
            file.start, file.end, size
        );
    } else {
        // protect our poor 6502 from huge files...
        if file.data.len() <= 0xfffe {
            size = file.data.len() as u16;
            data = &file.data;
        } else {
            size = 0xfffe;
            data = &file.data[0x0..0xfffe];
        }

        println!("serve {} raw: {:x}", if wide { "wide" } else { "" }, size);
    }
    if !no_header {
        port.write_u16::<LittleEndian>(size)?;
    }

    let chunk_size = if wide { 512 } else { 256 };
    for (i, chunk) in data.chunks(chunk_size).enumerate() {
        // print!("waiting for sync ...");
        // stdout().flush();
        let mut wide_chunk = [0u8; 512];
        let chunk = if wide && chunk.len() < chunk_size {
            wide_chunk[..chunk.len()].copy_from_slice(chunk);
            &wide_chunk
        } else {
            chunk
        };
        match port.read_u8() {
            Ok(b'b') => (),

            Ok(c) => {
                println!("\nunknown command: {:x}", c);
                return Err(anyhow!("unknown command: {:x}", c));
            }
            Err(e) => {
                println!("\nIO error: {:?}", e);
                return Err(anyhow!("\nIO error: {:?}", e));
            }
        }
        print!("\rsend chunk: {:04} {}", i, chunk.len());
        stdout().flush()?;

        // for c in chunk {
        //     port.write_u8(*c);
        // }
        for c in chunk {
            sum1 = sum1.wrapping_add(*c);
            sum2 = sum1.wrapping_add(sum2);
        }
        port.write_all(chunk).unwrap();
        port.flush()?;
        print!("\r");
        stdout().flush()?;
        // std::thread::sleep(Duration::from_secs(1))
    }
    println!("\ndone.");
    println!("fletch16: {:02x}{:02x}", sum2, sum1);
    Ok(())
    // loop {}
}
