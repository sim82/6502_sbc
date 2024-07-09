pub fn guess_program_space(f: &[u8]) -> (usize, usize) {
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
    (start, end)
}
