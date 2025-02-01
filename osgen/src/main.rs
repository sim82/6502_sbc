use askama::Template;
use clap::Parser;
use indexmap::IndexMap;
use serde::Deserialize;

#[derive(Parser)]
#[command(version, about)]
struct Args {
    input_config: String,

    #[arg(long, short)]
    ld65_config: Option<String>,

    #[arg(long, short)]
    import: Option<String>,

    #[arg(long, short)]
    functable: Option<String>,
}

struct OsCall {
    exported_name: String,
    implementation: String,
    is_last: bool,
}

#[derive(Template)]
#[template(path = "ld65_config.cfg")]
struct CfgTemplate {
    os_calls: Vec<OsCall>,
}

#[derive(Template)]
#[template(path = "import.inc")]
struct ImportsInc {
    os_calls: Vec<OsCall>,
}

#[derive(Template)]
#[template(path = "func_table.inc")]
struct FuncTableInc {
    os_calls: Vec<OsCall>,
}

impl CfgTemplate {
    fn from_config(input_cfg: &Config) -> Self {
        let os_calls = read_os_calls(input_cfg);
        Self { os_calls }
    }
}

impl ImportsInc {
    fn from_config(input_cfg: &Config) -> Self {
        let os_calls = read_os_calls(input_cfg);
        Self { os_calls }
    }
}
impl FuncTableInc {
    fn from_config(input_cfg: &Config) -> Self {
        let os_calls = read_os_calls(input_cfg);
        Self { os_calls }
    }
}
fn read_os_calls(input_cfg: &Config) -> Vec<OsCall> {
    let mut os_calls = Vec::new();
    for (i, (name, call)) in input_cfg.os_calls.iter().enumerate() {
        os_calls.push(OsCall {
            exported_name: name.clone(),
            implementation: call.implementation.clone(),
            is_last: i == input_cfg.os_calls.len() - 1,
        })
    }
    os_calls
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
    let args = Args::parse();
    let input_file = std::fs::read_to_string(args.input_config).expect("failed to read input file");
    let input_cfg = toml::from_str(&input_file).expect("failed to deserialize config file");

    if let Some(ld65_config) = args.ld65_config {
        let cfg_template = CfgTemplate::from_config(&input_cfg);
        let cfg = cfg_template.render().expect("failed to render ld65 config");
        std::fs::write(ld65_config, cfg).expect("failed to write ld65 config");
    }
    if let Some(import) = args.import {
        let cfg_template = ImportsInc::from_config(&input_cfg);
        let cfg = cfg_template.render().expect("failed to render import inc");
        std::fs::write(import, cfg).expect("failed to write import inc");
    }
    if let Some(functable) = args.functable {
        let cfg_template = FuncTableInc::from_config(&input_cfg);
        let cfg = cfg_template
            .render()
            .expect("failed to render functable inc");
        std::fs::write(functable, cfg).expect("failed to write functable inc");
    }
    // let mut cfg = CfgTemplate {
    //     os_calls: vec![
    //         OsCall::new("os_call1"),
    //         OsCall::new("os_call2"),
    //         OsCall::new("os_call3"),
    //     ],
    // };
    // let len = cfg.os_calls.len();
    // cfg.os_calls[len - 1].is_last = true;
}
