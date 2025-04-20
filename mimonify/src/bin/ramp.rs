use std::ops::RangeInclusive;

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

            let mf = 1.0 / p;
            println!("{}, {}: {}", freq, p, mf * 256.0 * 256.0);
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

    for x in 0..=255 {
        println!("{} {} {}", x, y >> (8), yf.rem_euclid(1.0) * 256.0);
        y += m;
        yf += mf;
        y %= 256 * 256;
    }
}
