use std::process::Command;

use crate::{Error, Result};

pub fn run_command(mut cmd: Command) -> Result<String> {
    let output = match cmd.output() {
        Ok(o) => o,
        Err(e) => {
            return Err(Error::Command(e, cmd));
        }
    };
    if !output.status.success() {
        let stderr = String::from_utf8_lossy(&output.stderr).to_string();
        return Err(Error::CommandStatus(output.status, cmd, stderr));
    }
    Ok(String::from_utf8_lossy(&output.stdout).to_string())
}
