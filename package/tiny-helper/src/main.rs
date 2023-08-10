#![no_std]
#![no_main]
#![warn(clippy::pedantic)]

extern crate alloc;

use alloc::{format, string::String};
use tiny_cli::Parser;

use crate::cli::HelperOpts;

mod cli;
mod diff;

#[no_mangle]
fn main() -> i32 {
    match run_cmd() {
        Ok(_) => {}
        Err(e) => {
            unix_print::unix_eprintln!("Failed to run command: {e}");
        }
    }
    0
}

fn run_cmd() -> Result<(), String> {
    let mut args = tiny_std::env::args();
    let _slf = args.next();
    let opts =
        cli::HelperOpts::parse(&mut args).map_err(|e| format!("Failed to parse args: {e}"))?;
    unix_print::unix_println!("Got opts {opts:?}");
    match opts {
        HelperOpts { diff: Some(diff) } => {
            diff.run_diff()?;
        }
        opts => {
            return Err(format!("Supplied invalid args: {opts:?}"));
        }
    }
    Ok(())
}
