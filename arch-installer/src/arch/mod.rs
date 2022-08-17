use crate::debug;
use crate::disks::write_or_overwrite;
use crate::error::Result;
use crate::process::run_binary;
use std::os::unix::process::CommandExt;

pub fn pacstrap_and_enter() -> Result<()> {
    debug!("Running pacstrap");
    run_binary(
        "pacstrap",
        vec!["/mnt", "base", "base-devel", "linux", "linux-firmware"],
        None,
    )?;
    debug!("Generating fstab");
    let fstab = run_binary("genfstab", vec!["-U", "-p", "/mnt"], None)?;
    debug!("Writing fstab");
    write_or_overwrite("/mnt/etc/fstab", fstab.stdout.as_ref())?;
    debug!("Entering arch-chroot");
    std::process::Command::new("arch-chroot").arg("/mnt").exec();
    Ok(())
}
