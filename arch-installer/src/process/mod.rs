use crate::debug;
use crate::error::{Error, Result};
use std::io::{Stderr, Write};
use std::process::{Output, Stdio};

pub fn get_password() -> Result<String> {
    let pwd = rpassword::prompt_password("Enter cryptodisk password")
        .map_err(|e| Error::Process(format!("Failed to get password from stdin {e}")))?;
    let pwd2 = rpassword::prompt_password("Repeat cryptodisk password")
        .map_err(|e| Error::Process(format!("Failed to get password from stdin {e}")))?;
    if pwd == pwd2 {
        Ok(pwd)
    } else {
        Err(Error::Process("Passwords do not match".to_owned()))
    }
}

pub fn run_binary(bin: &str, args: Vec<&str>, input: Option<&str>) -> Result<Output> {
    let mut child = std::process::Command::new(bin)
        .args(args)
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .spawn()
        .map_err(|e| Error::Process(format!("Failed to spawn process {bin} {e}")))?;
    if let Some(input) = input {
        let stdin_ref = child.stdin.as_mut();
        let stdin = &mut stdin_ref
            .ok_or_else(|| Error::Process(format!("Failed to get spawned child handle '{bin}'")))?;
        stdin
            .write(format!("{}\n", input).as_bytes())
            .map_err(|e| Error::Process(format!("Failed to write input to '{bin}' stdin {e}")))?;
    }
    debug!("Waiting for output from {bin}");
    let output = child
        .wait_with_output()
        .map_err(|e| Error::Process(format!("Failed to wait for output from '{bin}' {e}")))?;
    if output.status.success() {
        Ok(output)
    } else {
        Err(Error::Process(format!(
            "'{bin}' failed with exit code: {:?}, stduout: {:?}",
            output.status.code(),
            String::from_utf8(output.stderr)
        )))
    }
}
