use crate::debug;
use crate::error::{Error, Result};
use std::io::Write;
use std::process::{Child, Output, Stdio};

pub fn get_password() -> Result<String> {
    let pwd = rpassword::prompt_password("Enter cryptodisk password:")
        .map_err(|e| Error::Process(format!("Failed to get password from stdin {e}")))?;
    let pwd2 = rpassword::prompt_password("Repeat cryptodisk password:")
        .map_err(|e| Error::Process(format!("Failed to get password from stdin {e}")))?;
    if pwd == pwd2 {
        Ok(pwd)
    } else {
        Err(Error::Process("Passwords do not match".to_owned()))
    }
}

pub struct ForkedProc {
    inner: Child,
    dbg_command: String,
}

pub fn spawn_binary(bin: &str, args: Vec<&str>, input: Option<&str>) -> Result<ForkedProc> {
    let mut child = std::process::Command::new(bin)
        .args(&args)
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::null())
        .spawn()
        .map_err(|e| Error::Process(format!("Failed to spawn process {bin} {:?} {e}", args)))?;
    if let Some(input) = input {
        let stdin_ref = child.stdin.as_mut();
        let stdin = &mut stdin_ref.ok_or_else(|| {
            Error::Process(format!(
                "Failed to get spawned child handle '{bin}' {:?}",
                args
            ))
        })?;
        stdin
            .write(format!("{}\n", input).as_bytes())
            .map_err(|e| {
                Error::Process(format!(
                    "Failed to write input to '{bin}' {:?} stdin {e}",
                    args
                ))
            })?;
    }
    Ok(ForkedProc {
        inner: child,
        dbg_command: format!("{bin} {args:?}"),
    })
}

pub fn await_children(children: Vec<ForkedProc>) -> Result<Vec<Output>> {
    let mut output = vec![];
    for child in children {
        let out = child
            .inner
            .wait_with_output()
            .map_err(|e| Error::Process(format!("Await child '{}' {e}", child.dbg_command)))?;
        if out.status.success() {
            output.push(out);
        } else {
            return Err(Error::Process(format!(
                "Await child, status error '{}' {:?}",
                child.dbg_command, out.status
            )));
        }
    }
    Ok(output)
}

pub fn run_binary(
    bin: &str,
    args: Vec<&str>,
    input: Option<&str>,
    leak_stdout: bool,
) -> Result<Output> {
    let mut child = std::process::Command::new(bin)
        .args(&args)
        .stdin(Stdio::piped())
        .stdout(if leak_stdout {
            Stdio::inherit()
        } else {
            Stdio::piped()
        })
        .stderr(Stdio::piped())
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
            "command: '{bin} {:?}' failed with exit code: {:?}, stduout: {:?}",
            output.status.code(),
            args,
            String::from_utf8(output.stderr)
        )))
    }
}

#[cfg(test)]
mod tests {
    use crate::process::run_binary;

    #[test]
    fn test_spawn_with_output() {
        let res = run_binary("echo", vec!["abc"], None, false).unwrap();
        eprintln!("{:?}", String::from_utf8(res.stdout));
    }
}
