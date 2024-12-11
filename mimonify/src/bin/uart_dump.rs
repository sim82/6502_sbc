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
        "/dev/serial/by-id/usb-Raspberry_Pi_Debug_Probe__CMSIS-DAP__E6633861A37D6E38-if01",
    )
    .unwrap();
    port.reconfigure(&|settings| {
        settings.set_baud_rate(serial::Baud115200).unwrap();
        settings.set_char_size(serial::Bits8);
        settings.set_parity(serial::ParityNone);
        settings.set_stop_bits(serial::Stop1);
        settings.set_flow_control(serial::FlowNone);
        Ok(())
    })
    .unwrap();
    port.set_timeout(Duration::from_secs(5)).unwrap();
    let mut file = std::fs::File::create("out.bin").unwrap();
    let mut buf = [0u8; 4096];
    let spec = hound::WavSpec {
        channels: 1,
        sample_rate: 44100,
        bits_per_sample: 16,
        sample_format: hound::SampleFormat::Int,
    };
    let mut writer = hound::WavWriter::create("out.wav", spec).unwrap();
    // port.read_exact(&mut buf).unwrap();
    let mut tmp = [0u8; 128];
    port.read_exact(&mut tmp);
    for _ in 0..20 {
        port.read_exact(&mut buf).unwrap();
        for s in buf.chunks(2) {
            let s16 = (s[0] as u16) | (s[1] as u16) << 8;
            writer.write_sample(s16 as i16).unwrap();
            // writer.write_sample(256 as i16).unwrap();
        }
        file.write_all(&buf).unwrap();
    }
}
