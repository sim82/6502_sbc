use anyhow::anyhow;
use std::{
    io::{BufWriter, SeekFrom},
    ops::Shr,
};

use byteorder::{LittleEndian, ReadBytesExt, WriteBytesExt};
type Result<T> = anyhow::Result<T>;
const NUM_LINKS: usize = 256 * 256;

struct Cfs1 {
    links: [usize; NUM_LINKS],
}

impl Default for Cfs1 {
    fn default() -> Self {
        let mut links = [0; NUM_LINKS];
        for (i, link) in links.iter_mut().enumerate() {
            if i < NUM_LINKS - 1 {
                *link = i + 1;
            }
        }
        Self { links }
    }
}
impl Cfs1 {
    pub fn write<T: std::io::Write + std::io::Seek>(&self, w: &mut T) -> Result<()> {
        for (i, link) in self.links.iter().enumerate() {
            let block = i / 256;
            let block_offs = block * 512;
            let link_in_block = i % 256;
            w.seek(SeekFrom::Start((block_offs + link_in_block) as u64))?;
            w.write_u8((link & 0xff) as u8)?;
            w.seek(SeekFrom::Start((block_offs + 256 + link_in_block) as u64))?;
            w.write_u8((link & 0xff00).shr(8) as u8)?;
        }
        Ok(())
    }
    fn alloc(&mut self, n: usize) -> Result<usize> {
        if n == 0 {
            return Err(anyhow!("alloc size 0"));
        }
        let mut start = 0;
        let mut last = 0;
        for i in 0..n {
            let next_free = self.links[0];
            if next_free == 0 {
                return Err(anyhow!("no free blocks"));
            }
            self.links[0] = self.links[next_free];
            if start == 0 {
                start = next_free;
            }

            if last != 0 {
                self.links[last] = next_free;
            }
            self.links[next_free] = 0;
            last = next_free;
        }
        Ok(start)
    }
    fn free(&mut self, mut start: usize) {
        let old_next = self.links[0];
        self.links[0] = start;
        loop {
            let next = self.links[start];
            if next == 0 {
                break;
            }
            start = next;
        }
        self.links[start] = old_next;
    }
    fn print_chain(&self, mut start: usize) {
        print!("{}", start);
        loop {
            let next = self.links[start];
            if next == 0 {
                break;
            }
            print!(" -> {}", next);
            start = next;
        }
        println!();
    }
}
fn main() -> anyhow::Result<()> {
    let mut fs = Cfs1::default();
    let b1 = fs.alloc(512)?;
    let b2 = fs.alloc(256)?;
    println!("{:?} {:?}", b1, b2);
    fs.print_chain(b1);
    fs.print_chain(b2);
    fs.print_chain(0);

    fs.free(b1);
    fs.free(b2);
    let b3 = fs.alloc(512)?;
    let b4 = fs.alloc(256)?;
    let b5 = fs.alloc(10)?;
    let b6 = fs.alloc(5)?;

    fs.print_chain(b3);
    fs.print_chain(b4);
    fs.print_chain(0);
    fs.print_chain(b5);
    fs.print_chain(b6);

    let mut f = BufWriter::new(std::fs::File::create("cfs1.bin")?);
    fs.write(&mut f)?;
    Ok(())
}
