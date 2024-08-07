use std::env;

use mimonify::guess_program_space;

fn main() {
    let args: Vec<String> = env::args().collect();
    if args.len() < 2 {
        panic!("missing binary name");
    }
    let f = std::fs::read(&args[1]).unwrap();

    // code find heuristic:
    // start: first 16 byte chunk that contains non-zero bytes
    // end: next 16 byte chunk after start that contains only zero bytes
    // i.e. this assumes that code starts on a 16byte boundary and that there
    // are no spans of 16 or more zeros inside the code (don't put empty space in the program...)
    let (start, end) = guess_program_space(&f);
    let data = &f[start..end];
    println!("send Ea");

    let mut cur = start;
    let chunk_size = 240; // minicom seems to have a 500 byte per line limit. Try to stay within...
    for c in data.chunks(chunk_size) {
        #[allow(clippy::format_collect)] // no one cares, those are 8bit programs...
        let hexblob = c.iter().map(|c| format!("{:02x}", c)).collect::<String>();
        println!("send t{:04x}p{}", cur, hexblob);
        cur += c.len();
    }
    println!("send t{:04x}r", start);
}
