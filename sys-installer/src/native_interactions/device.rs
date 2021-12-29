use crate::cfg::{FsType, ParsedConfig, ParsedDevice};
use crate::error::Error::PathConversionError;
use crate::error::Result;
use crate::native_interactions::cmd::run_command;
use crate::util::file_system::{create_dir_if_not_exists, read_file};
use std::path::PathBuf;

pub async fn umount(config: &ParsedConfig) -> Result<()> {
    for line in read_file("/proc/mounts").await?.lines() {
        if line.contains(&config.root_dev.dev) {
            run_command("umount", &["-R", &config.host_mount_point]).await?;
        }
    }
    for dev in &config.other_devs {
        if dev.fs_type == FsType::Swap {
            for line in read_file("/proc/swaps").await?.lines() {
                if line.contains(&dev.dev) {
                    run_command("swapoff", &[&dev.dev]).await?;
                }
            }
        }
    }
    Ok(())
}

pub async fn recreate_filesystems(config: &ParsedConfig) -> Result<()> {
    let mut futures = Vec::new();
    futures.push(mkfs(&config.root_dev));
    futures.push(mkfs(&config.boot_dev));
    for dev in &config.other_devs {
        futures.push(mkfs(dev));
    }
    futures::future::try_join_all(futures).await?;
    Ok(())
}

async fn mkfs(parsed_device: &ParsedDevice) -> Result<()> {
    match parsed_device.fs_type {
        FsType::Ext4 => run_command("mkfs.ext4", &["-F", &parsed_device.dev]).await?,
        FsType::Vfat => run_command("mkfs.vfat", &["-F32", &parsed_device.dev]).await?,
        FsType::Swap => run_command("mkswap", &[&parsed_device.dev]).await?,
    };
    Ok(())
}

pub async fn mount_filesystems(config: &ParsedConfig) -> Result<()> {
    run_command("mount", &[&config.root_dev.dev, &config.host_mount_point]).await?;
    create_dir_if_not_exists(
        PathBuf::from(&config.host_mount_point)
            .join(&config.boot_dev.mount_point.trim_start_matches("/")),
    )
    .await?;

    let boot_mount = PathBuf::from(&config.host_mount_point)
        .join(&config.boot_dev.mount_point.trim_start_matches("/"));
    if let Some(m) = boot_mount.to_str() {
        run_command("mount", &[&config.boot_dev.dev, &m]).await?;
    } else {
        return Err(PathConversionError(format!("{:?}", boot_mount)));
    }
    for dev in &config.other_devs {
        match dev.fs_type {
            FsType::Swap => {
                run_command("swapon", &[&dev.dev]).await?;
            }
            _ => {
                let mount = PathBuf::from(&config.host_mount_point)
                    .join(&dev.mount_point.trim_start_matches("/"));
                match mount.to_str() {
                    Some(s) => {
                        create_dir_if_not_exists(&mount).await?;
                        run_command("mount", &[&dev.dev, s]).await?;
                    }
                    None => return Err(PathConversionError(format!("{:?}", mount))),
                }
            }
        }
    }
    Ok(())
}

pub async fn mount_pseudo_filesystems(config: &ParsedConfig) -> Result<()> {
    let root_mount = &config.host_mount_point;
    println!("Mounting pseudo filesystems");
    futures::future::try_join_all([
        run_command(
            "mount",
            &["--types", "proc", "/proc", &format!("{}/proc", root_mount)],
        ),
        run_command(
            "mount",
            &["--rbind", "/sys", &format!("{}/sys", root_mount)],
        ),
        run_command(
            "mount",
            &["--rbind", "/dev", &format!("{}/dev", root_mount)],
        ),
        run_command("mount", &["--bind", "/run", &format!("{}/run", root_mount)]),
    ])
    .await?;
    futures::future::try_join_all([
        run_command("mount", &["--make-rslave", &format!("{}/sys", root_mount)]),
        run_command("mount", &["--make-rslave", &format!("{}/dev", root_mount)]),
        run_command("mount", &["--make-slave", &format!("{}/run", root_mount)]),
    ])
    .await?;
    Ok(())
}
