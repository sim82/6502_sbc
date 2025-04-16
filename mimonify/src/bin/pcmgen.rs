use core::f32;

fn main() {
    print!(".byte    ");
    for i in 0..256 {
        let x = (i as f32) / 255.0;

        let y = (x * 2.0 * f32::consts::PI).sin();
        let y = ((y * 127.0) + 128.0) as u8;
        print!("${:x}, ", y)
    }
    println!();
}
