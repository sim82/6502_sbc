pub fn guess_program_space(f: &[u8]) -> (usize, usize) {
    // let mut start = 0;
    // let mut end = 0;

    // let mut iter: Vec<_> = f.chunks(256).enumerate().collect();

    // for (i, chunk) in &mut iter {
    //     if chunk.iter().any(|c| *c != 0) {
    //         start = i * 256;
    let start = f.iter().position(|&c| c != 0).unwrap_or(0);
    let end = f.iter().rposition(|&c| c != 0).map_or(0, |p| p + 1);
    
    let start = (start / 256) * 256;
    let end = ((end + 255) / 256) * 256;
    
    (start, end)
}
