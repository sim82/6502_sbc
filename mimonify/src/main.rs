fn main() {
    let f = std::fs::read("12_sieve_16").unwrap();

    // code find heuristic:
    // start: first 16 byte chunk that contains non-zero bytes
    // end: next 16 byte chunk after start that contains only zero bytes
    // i.e. this assumes that code starts on a 16byte boundary and that there
    // are no spans of 16 or more zeros inside the code (don't put empty space in the program...)
    let mut start = 0;
    let mut end = 0;
    let mut iter = f.chunks(16).enumerate();
    for (i, chunk) in &mut iter {
        if chunk.iter().any(|c| *c != 0) {
            start = i * 16;
            break;
        }
    }

    for (i, chunk) in iter {
        if !chunk.iter().any(|c| *c != 0) {
            end = i * 16;
            break;
        }
    }
    let data = &f[start..end];
    println!("Ea");

    #[allow(clippy::format_collect)] // no one cares, those are 8bit programs...
    let hexblob = data
        .iter()
        .map(|c| format!("{:02x}", c))
        .collect::<String>();
    println!("t{:04x}p{}xt{:04x}r", start, hexblob, start);
}
