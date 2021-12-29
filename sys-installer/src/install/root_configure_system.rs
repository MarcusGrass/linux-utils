use crate::cfg::ParsedConfig;
use crate::error::Result;
use crate::native_interactions::cmd::run_command;
use crate::native_interactions::emerge::root_stage_install_essential;
use crate::native_interactions::progress::{default_bar, show_message_then_increment};
use crate::opt::CfgPath;
use std::os::unix::prelude::CommandExt;

pub(crate) async fn root_configure_system(path: &CfgPath) -> Result<()> {
    let cfg = ParsedConfig::parse_from_path(&path.cfg).await?;
    let pb = default_bar(3);

    root_stage_install_essential()?;
    show_message_then_increment(
        "Enable bluetooth".to_owned(),
        run_command("systemctl", &["enable", "--now", "bluetooth"]),
        &pb,
    )
    .await?;
    show_message_then_increment(
        "Enable ntp".to_owned(),
        run_command("systemctl", &["enable", "--now", "ntpd"]),
        &pb,
    )
    .await?;
    show_message_then_increment(
        "Create user".to_owned(),
        futures::future::try_join_all([
            run_command("useradd", &["-m", &cfg.user_name]),
            run_command("usermod", &["-aG", "wheel", &cfg.user_name]),
        ]),
        &pb,
    )
    .await?;
    println!("Set user passwd then run the final install");
    std::process::Command::new("passwd")
        .arg(&cfg.user_name)
        .exec();
    Ok(())
}
