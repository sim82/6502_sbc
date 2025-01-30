use askama::Template;

struct OsCall {
    exported_name: String,
    is_last: bool,
}
impl OsCall {
    pub fn new(name: &str) -> Self {
        Self {
            exported_name: name.into(),
            is_last: false,
        }
    }
}
#[derive(Template)]
#[template(path = "my_sbc_os.cfg")]
struct CfgTemplate {
    os_calls: Vec<OsCall>,
}
fn main() {
    let mut cfg = CfgTemplate {
        os_calls: vec![
            OsCall::new("os_call1"),
            OsCall::new("os_call2"),
            OsCall::new("os_call3"),
        ],
    };
    let len = cfg.os_calls.len();
    cfg.os_calls[len - 1].is_last = true;

    println!("{}", cfg.render().unwrap());
}
