use std::collections::HashMap;

use askama::Template;
use clap::Parser;
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

#[derive(Debug)]
struct OsCall {
    exported_name: String,
    implementation: String,
    ordinal: usize,
    docs: Vec<String>,
    is_last: bool,
}

#[derive(Template)]
#[template(path = "ld65_config.cfg.jinja")]
struct CfgTemplate {
    os_calls: Vec<OsCall>,
}

#[derive(Template)]
#[template(path = "import.inc.jinja")]
struct ImportsInc {
    os_calls: Vec<OsCall>,
}

#[derive(Template)]
#[template(path = "func_table.asm.jinja")]
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
    let mut os_calls: Vec<_> = input_cfg
        .os_calls
        .iter()
        .map(|(name, call)| {
            //
            let mut docs = vec![call.description.clone()];
            if let Some(calling) = &call.calling {
                docs.append(&mut calling.clone());
            }

            OsCall {
                exported_name: name.clone(),
                implementation: call.implementation.clone(),
                ordinal: call.ordinal,
                // docu_string: call
                //     .calling
                //     .map_or(String::new(), |calling| get_docu_string(&calling)),
                docs,
                is_last: false,
            }
        })
        .collect();

    os_calls.sort_by_key(|call| call.ordinal);
    for (i, call) in os_calls.iter().enumerate() {
        if i != call.ordinal {
            panic!("bad ordinal at {:?}", call);
        }
    }
    os_calls.last_mut().map(|last| last.is_last = true);
    os_calls
}

#[derive(Deserialize, Debug)]
struct ConfigOsCall {
    implementation: String,
    ordinal: usize,
    description: String,
    calling: Option<Vec<String>>,
}
#[derive(Deserialize, Debug)]
struct Config {
    os_calls: HashMap<String, ConfigOsCall>,
}
fn main() {
    let args = Args::parse();
    let input_file = std::fs::read_to_string(args.input_config).expect("failed to read input file");
    let input_cfg: Config = toml::from_str(&input_file).expect("failed to deserialize config file");

    println!("osgen: {} functions:", input_cfg.os_calls.len());
    let mut order = input_cfg
        .os_calls
        .iter()
        .map(|(k, v)| (v.ordinal, k))
        .collect::<Vec<_>>();
    order.sort_by_key(|(ordinal, _)| *ordinal);
    for (_, name) in order {
        let Some(os_call) = input_cfg.os_calls.get(name) else {
            continue;
        };
        println!(
            "- ({}) {} -> {}: {}",
            os_call.ordinal, name, os_call.implementation, os_call.description
        );
    }
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
}
