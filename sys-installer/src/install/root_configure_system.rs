use crate::error::Result;
use crate::native_interactions::cmd::run_command;
use crate::native_interactions::emerge::root_stage_install_essential;
use crate::native_interactions::progress::{default_bar, show_message_then_increment};

pub(crate) async fn root_configure_system() -> Result<()> {
    root_stage_install_essential()?;
    let pb = default_bar(5);
    show_message_then_increment(
        "Enable dhcpcd".to_owned(),
        run_command("systemctl", &["enable", "--now", "dhcpcd"]),
        &pb,
    )
    .await?;
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
    Ok(())
}
