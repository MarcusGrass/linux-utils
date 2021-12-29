use crate::cfg::{FsType, ParsedConfig};
use crate::error::{Error, Result};
use crate::native_interactions::cmd::run_command;
use crate::native_interactions::emerge::chroot_finalize_install_essential;
use crate::native_interactions::progress::{default_bar, show_message_then_increment};
use crate::opt::CfgPath;
use crate::util::file_system::create_file_if_not_identical_exists;
use std::ops::Add;
use std::os::unix::prelude::CommandExt;

pub(crate) async fn chroot_gentoo_finalize(path: &CfgPath) -> Result<()> {
    let cfg = ParsedConfig::parse_from_path(&path.cfg).await?;
    let pb = default_bar(4);
    show_message_then_increment(
        "Running grub install".to_owned(),
        run_command(
            "grub-install",
            &[
                "--target=x86_64-efi",
                &format!("--efi-directory={}", &cfg.boot_dev.mount_point),
                "--bootloader-id=GRINUX",
            ],
        ),
        &pb,
    )
    .await?;
    show_message_then_increment(
        "Generating vanilla initramfs".to_owned(),
        run_command(
            "genkernel",
            &[
                "--install",
                "--kernel-config=/usr/src/linux/.config",
                "initramfs",
            ],
        ),
        &pb,
    )
    .await?;
    show_message_then_increment(
        "Creating grub cfg".to_owned(),
        run_command("grub-mkconfig", &["-o", "/boot/grub/grub.cfg"]),
        &pb,
    )
    .await?;
    let _ = show_message_then_increment(
        "Enable dhcpcd".to_owned(),
        run_command("systemctl", &["enable", "--now", "dhcpcd"]),
        &pb,
    )
    .await;
    pb.finish_with_message("Configured bootloader");
    chroot_finalize_install_essential()?;
    println!("Generating fstab");
    let fstab = generate_fs_tab(&cfg).await?;
    create_file_if_not_identical_exists("/etc/fstab", format!("{}\n", fstab).as_bytes()).await?;
    println!("Set root passwd, then check /etc/fstab, reboot, and continue");
    std::process::Command::new("/bin/passwd").exec();
    Ok(())
}

async fn generate_fs_tab(config: &ParsedConfig) -> Result<String> {
    let output = run_command("mount", &[]).await?;
    let lines = String::from_utf8(output.stdout)?;
    let mut devices = vec![&config.root_dev, &config.boot_dev];
    let mut entries = Vec::with_capacity(devices.len());
    for dev in &config.other_devs {
        if dev.fs_type == FsType::Swap {
            entries.push(format!("{}\tswap\tswap\tdefaults\t0 0", &dev.dev));
        }
        devices.push(dev);
    }
    for line in lines.lines() {
        for dev in &devices {
            if dev.fs_type == FsType::Swap {
                continue;
            }
            if line.contains(&dev.dev) {
                let mut trimmed = line.replace(" on ", "\t");
                trimmed = trimmed.replace(" type ", "\t");
                trimmed = trimmed.replace("(", "");
                trimmed = trimmed.replace(")", "");
                if trimmed.contains("\t/\t") {
                    trimmed = trimmed.add("\t0 1");
                } else {
                    trimmed = trimmed.add("\t0 2");
                }
                entries.push(trimmed);
            }
        }
    }
    if entries.len() != devices.len() {
        Err(Error::FstabGenerationError)
    } else {
        Ok(entries.join("\n"))
    }
}
