use std::io::{BufWriter, Write};

use byteorder::WriteBytesExt;

fn main() {
    let mut stdout = BufWriter::new(std::io::stdout());
    for i in 0..1000000 {
        let head = format!(
            "sector {} 0x{:x} 0x{:x} 0x{:x}",
            i,
            i % 256,
            (i >> 8) % 256,
            (i >> 16) % 256
        );
        stdout.write_all(head.as_bytes()).unwrap();
        for j in head.len()..512 {
            stdout.write_u8((j % 128) as u8).unwrap()
        }
    }
}
