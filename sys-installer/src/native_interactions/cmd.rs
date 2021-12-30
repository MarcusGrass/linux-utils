use std::collections::HashMap;
use std::path::Path;
use std::process::Output;

use tokio::process::Command;

use crate::error::{Error, Result};

pub async fn run_in_dir(cmd: &str, args: &[&str], path: impl AsRef<Path>) -> Result<Output> {
    run_complete(cmd, args, HashMap::new(), path).await
}

pub async fn run_command(cmd: &str, args: &[&str]) -> Result<Output> {
    run_command_with_envs(cmd, args, HashMap::new()).await
}

pub async fn run_command_with_envs(
    cmd: &str,
    args: &[&str],
    env: HashMap<String, String>,
) -> Result<Output> {
    run_complete(cmd, args, env, "/").await
}

pub async fn run_complete(
    cmd: &str,
    args: &[&str],
    env: HashMap<String, String>,
    path: impl AsRef<Path>,
) -> Result<Output> {
    let mut cmd = Command::new(cmd);
    cmd.args(args);
    cmd.envs(env);
    cmd.current_dir(path);
    exec_command(cmd).await
}

async fn exec_command(mut cmd: Command) -> Result<Output> {
    match cmd.output().await {
        Ok(out) => {
            if out.status.success() {
                Ok(out)
            } else {
                let stdout = String::from_utf8(out.stdout)
                    .unwrap_or("Failed to convert stdout to utf-8".to_owned());
                let stderr = String::from_utf8(out.stderr)
                    .unwrap_or("Failed to convert stderr to utf-8".to_owned());
                Err(Error::CommandExecutionError(
                    format!("{:?}", cmd),
                    stdout,
                    stderr,
                ))
            }
        }
        Err(e) => Err(Error::CommandStartError(format!("{:?}", cmd), e)),
    }
}
