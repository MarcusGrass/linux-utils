use crate::cfg::ParsedConfig;
use crate::error::Result;
use crate::native_interactions::device::{mount_filesystems, mount_pseudo_filesystems, umount};
use crate::native_interactions::progress::{default_bar, show_message_then_increment};
use crate::opt::CfgPath;

pub(crate) async fn enter(cfg: &CfgPath) -> Result<()> {
    let cfg = ParsedConfig::parse_from_path(&cfg.cfg).await?;
    let pb = default_bar(3);
    show_message_then_increment("Unmounting".to_owned(), umount(&cfg), &pb).await?;
    show_message_then_increment("Mounting fs".to_owned(), mount_filesystems(&cfg), &pb).await?;
    show_message_then_increment(
        "Mounting Pseudo fs".to_owned(),
        mount_pseudo_filesystems(&cfg),
        &pb,
    )
    .await?;
    pb.finish_with_message(format!(
        "Mount complete chroot {} to enter",
        cfg.host_mount_point
    ));
    Ok(())
}
