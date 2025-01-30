use std::collections::BTreeMap;

use askama::Template;
use indexmap::IndexMap;
use serde::Deserialize;

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
impl CfgTemplate {
    fn from_config(input_cfg: &Config) -> Self {
        let mut cfg = CfgTemplate {
            os_calls: Vec::new(),
        };
        for (i, (name, _call)) in input_cfg.os_calls.iter().enumerate() {
            cfg.os_calls.push(OsCall {
                exported_name: name.clone(),
                is_last: i == input_cfg.os_calls.len() - 1,
            })
        }
        cfg
    }
}

#[derive(Deserialize, Debug)]
struct ConfigOsCall {
    implementation: String,
}
#[derive(Deserialize, Debug)]
struct Config {
    os_calls: IndexMap<String, ConfigOsCall>,
}
fn main() {
    let input_cfg: Config = toml::de::from_str(
        r#"
[os_calls]
    [os_calls.os_call1]
    implementation = "impl1"
        

    [os_calls.os_call3]
    implementation = "impl3"
    [os_calls.os_call2]
    implementation = "impl2"
    [os_calls.os_call4]
    implementation = "impl4"
        "#,
    )
    .unwrap();
    println!("{:?}", input_cfg);
    let cfg = CfgTemplate::from_config(&input_cfg);
    // let mut cfg = CfgTemplate {
    //     os_calls: vec![
    //         OsCall::new("os_call1"),
    //         OsCall::new("os_call2"),
    //         OsCall::new("os_call3"),
    //     ],
    // };
    // let len = cfg.os_calls.len();
    // cfg.os_calls[len - 1].is_last = true;

    println!("{}", cfg.render().unwrap());
}
