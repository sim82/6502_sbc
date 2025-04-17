fn main() {
    // let x1 = 0i32;
    // let x2 = 255i32;
    // let y1 = 2i32;
    // let y2 = 9i32;

    let x0 = 0i32;
    let x1 = 10i32;
    let y0 = 0i32;
    let y1 = 255i32;

    let dx = x1 - x0;
    let dy = (y1 - y0);
    let sx = 1;
    let sy = 1;
    let mut error = dx - dy;
    let mut x = x0;
    let mut y = y0;

    // let mut d = 2 * dy - dx;
    // let mut y = y0;

    // while i <= step {
    // for x in x0..=x1 {
    //     println!("{} {}, {}", x, y, d);
    //     if d > 0 {
    //         y += 1;
    //         d -= 2 * dx;
    //     }
    //     d += 2 * dy;
    // }
    let mut lasty = y;
    // loop {
    for _ in 0..512 * 100 {
        // let e2 = 2 * error;
        println!("{} {} {} {}", x, y, error, y - lasty);
        if error >= -dy / 2 {
            // if x == 255 {
            //     break;
            // }
            error -= dy;
            lasty = y;
            x += sx;
            x %= 256;
        }
        if error <= dx / 2 {
            // if y == y1 {
            //     break;
            // }
            error += dx;
            y += sy;
            y %= 256;
        }
    }
}
