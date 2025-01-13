use bs02::vm::Vm;

fn main() {
    let args = std::env::args();
    if args.len() != 2 {
        println!("missing arg");
        return;
    }

    let code = std::fs::read(args.last().unwrap()).expect("failed to read code");
    let mut vm = Vm::new(&code);
    vm.run();
}
