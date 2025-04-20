use std::io::Write;
use std::ops::RangeInclusive;

use clap::Parser;

#[derive(Parser)]
#[command(version, about)]
struct Args {
    output_file: String,
}
fn main() {
    // let x0 = 0;
    // let x1 = 45;
    // let y0 = 0;
    // let y1 = 255;

    let args = Args::parse();

    let mut output_file =
        std::fs::File::create(args.output_file).expect("failed to create output file");
    let scale = include!("scale.inc");

    const SAMPLE_RATE: f64 = 10000.0;
    let params = scale
        .iter()
        .map(|freq| {
            let p = SAMPLE_RATE / freq;

            let mf = 1.0 / p;
            // println!("{}, {}: {}", freq, p, mf * 256.0 * 256.0);
            // m

            let m = (mf * 256.0 * 256.0).round() as u32;
            (freq, mf, m)
        })
        .collect::<Vec<_>>();
    writeln!(output_file, "SCALE_LEN = {}", scale.len()).unwrap();
    writeln!(output_file, "scale_m_l:").unwrap();
    for (freq, mf, m) in &params {
        writeln!(
            output_file,
            ".byte ${:x}\t# {}Hz, {}, {}",
            m & 0xff,
            freq,
            mf,
            m
        )
        .unwrap();
        println!("{}: {}", freq, m);
    }
    writeln!(output_file, "scale_m_h:").unwrap();
    for (freq, mf, m) in &params {
        writeln!(
            output_file,
            ".byte ${:x}\t# {}Hz, {}, {}",
            (m >> 8) & 0xff,
            freq,
            mf,
            m
        )
        .unwrap();
        println!("{}: {}", freq, m);
    }
    if false {
        // let mut m = slope(0..=90, 0..=256); //((y1 - y0) << 8) / (x1 - x0);
        let mf = params[13].1;
        let m = (mf * 256.0 * 256.0).round() as u32;
        // let m = (params[13] * 256.0 * 256.0) as u32;

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
}
