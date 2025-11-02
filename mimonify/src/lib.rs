pub fn guess_program_space(f: &[u8]) -> (usize, usize) {
    let mut start = 0;
    let mut end = 0;
    let mut iter = f.chunks(256).enumerate();
    for (i, chunk) in &mut iter {
        if chunk.iter().any(|c| *c != 0) {
            start = i * 256;
            break;
        }
    }

    for (i, chunk) in iter {
        if !chunk.iter().any(|c| *c != 0) {
            end = i * 256;
            break;
        }
    }
    (start, end)
}
