use crate::error::{Error, Result};
use crate::native_interactions::cmd::run_command;
use std::io::BufRead;

pub async fn get_num_cpus() -> Result<u32> {
    let out = get_string_from_cmd("nproc", &[]).await?;
    match out.parse::<u32>() {
        Ok(u) => Ok(u),
        Err(_) => Err(Error::NumberParseError(out)),
    }
}

pub async fn get_string_from_cmd(cmd: &str, args: &[&str]) -> Result<String> {
    let out = run_command(cmd, args).await?;
    Ok(String::from_utf8(out.stdout)?.trim().to_owned())
}

pub fn read_number_from_stdin() -> Result<u32> {
    let out = read_string_from_stdin()?;
    match out.parse::<u32>() {
        Ok(u) => Ok(u),
        Err(_) => Err(Error::NumberParseError(out)),
    }
}

pub fn read_string_from_stdin() -> Result<String> {
    let mut buf = String::new();
    let stdin = std::io::stdin();
    let mut lock = stdin.lock();

    match lock.read_line(&mut buf) {
        Ok(_) => Ok(buf.trim().to_owned()),
        Err(_) => Err(Error::StdinReadError),
    }
}
