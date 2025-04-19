use std::ops::RangeInclusive;

fn slope(x: RangeInclusive<u32>, y: RangeInclusive<u32>, ps: u32) -> u32 {
    ((y.end() - y.start()) << (8 + ps)) / ((x.end() - x.start()) << 0)
}
fn main() {
    // let x0 = 0;
    // let x1 = 45;
    // let y0 = 0;
    // let y1 = 255;
    let scale = include!("scale.inc");

    const SAMPLE_RATE: f64 = 10000.0;
    let params = scale
        .iter()
        .map(|freq| {
            let p = SAMPLE_RATE / freq;
            const OVERRIDE: bool = !true;

            let (scale, shift) = match p {
                ..16.0 => (16.0, 4),
                ..32.0 => (8.0, 3),
                ..64.0 => (4.0, 2),
                ..128.0 => (2.0, 1),
                _ => (1.0, 0),
            };
            // let m = if OVERRIDE || p >= 128.0 {
            //     let pi = p as u32;
            //     slope(0..=pi, 0..=256, 0u32)
            // } else if p >= 64.0 {
            //     let pi = (p * 2.0) as u32;
            //     slope(0..=pi, 0..=256, 1u32)
            // } else if p >= 32.0 {
            //     let pi = (p * 4.0) as u32;
            //     slope(0..=pi, 0..=256, 2u32)
            // } else if p >= 16.0 {
            //     let pi = (p * 8.0) as u32;
            //     slope(0..=pi, 0..=256, 3u32)
            // } else {
            //     let pi = (p * 16.0) as u32;
            //     slope(0..=pi, 0..=256, 4u32)
            // };

            let x1 = (p * scale) as u32;
            let m = slope(0..=x1, 0..=256, shift);
            let mf = 1.0 / p;
            println!(
                "{}, {}, {}, {}: {}, {}",
                freq,
                p,
                scale,
                shift,
                m,
                mf * 256.0 * 256.0
            );
            // m
            mf
        })
        .collect::<Vec<_>>();
    // let mut m = slope(0..=90, 0..=256); //((y1 - y0) << 8) / (x1 - x0);
    let m = (params[13] * 256.0 * 256.0).round() as u32;
    // let m = (params[13] * 256.0 * 256.0) as u32;
    let mf = params[13];

    println!("m: {}", m);
    let mut y = 0;
    let mut yf: f64 = 0.0;
    let mut s = 20;

    for x in 0..=10000 {
        println!("{} {} {}", x, y >> (8), yf.rem_euclid(1.0) * 256.0);
        y += m;
        yf += mf;
        y %= 256 * 256;
    }
}
