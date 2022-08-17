use crate::device::{DeviceConfig, Devices};
use crate::error::{Error, Result};
use crate::process::{run_binary, spawn_binary, ForkedProc};
use crate::{await_children, debug};
use nix::mount::MsFlags;
use std::path::Path;
use std::process::Child;

pub fn init_cryptodisk(device_config: &DeviceConfig, crypt_password: &str) -> Result<ForkedProc> {
    debug!("Setting up device {:?}", device_config);
    spawn_binary(
        "cryptsetup",
        vec![
            "luksFormat",
            &device_config.device_path(),
            "--type",
            "luks1",
        ],
        Some(crypt_password),
    )
}

pub fn open_cryptodisk(device_config: &DeviceConfig, crypt_password: &str) -> Result<ForkedProc> {
    debug!("Opening device {:?}", device_config);
    spawn_binary(
        "cryptsetup",
        vec![
            "open",
            device_config.device_path().as_str(),
            &device_config.crypt_device_name,
        ],
        Some(crypt_password),
    )
}

pub fn create_filesystems(config: &Devices) -> Result<()> {
    debug!("Creating filesystems");
    debug!("Creating ext4 root");
    run_binary(
        "mkfs.ext4",
        vec!["-F", &config.root.crypt_device_path()],
        None,
    )?;
    debug!("Creating ext4 home");
    run_binary(
        "mkfs.ext4",
        vec!["-F", &config.home.crypt_device_path()],
        None,
    )?;
    debug!("Creating Fat32 efi");
    run_binary("mkfs.fat", vec!["-F32", &config.efi.device_path()], None)?;
    debug!("Creating swap");
    run_binary("mkswap", vec![&config.swap.crypt_device_path()], None)?;
    Ok(())
}

pub fn mount_disks(config: &Devices) -> Result<()> {
    debug!("Mounting devices {config:?}");
    ensure_dir_or_try_create("/mnt")?;
    debug!("Mount point /mnt ready.");
    debug!("Mounting root");
    run_binary(
        "mount",
        vec![&config.root.crypt_device_path(), "/mnt"],
        None,
    )?;
    ensure_dir_or_try_create("/mnt/home")?;
    ensure_dir_or_try_create("/mnt/efi")?;
    debug!("Mounting home, efi, and swap");
    let home = spawn_binary(
        "mount",
        vec![&config.home.crypt_device_path(), "/mnt/home"],
        None,
    )?;
    let efi = spawn_binary("mount", vec![&config.efi.device_path(), "/mnt/efi"], None)?;
    let swap = spawn_binary("swapon", vec![&config.swap.crypt_device_path()], None)?;
    await_children(vec![home, efi, swap])?;
    debug!("Mounting swap");

    debug!("Disks mounted");
    Ok(())
}

pub fn ensure_dir_or_try_create(path: impl AsRef<Path>) -> Result<()> {
    if let Ok(meta) = std::fs::metadata(&path) {
        if !meta.is_dir() {
            return Err(Error::Fs(format!(
                "File exists at {:?} but is not a dir",
                path.as_ref()
            )));
        }
    } else {
        debug!("Creating dir {:?}", path.as_ref());
        std::fs::create_dir(&path)
            .map_err(|e| Error::Fs(format!("Failed to create dir {:?} {e}", path.as_ref())))?;
    }
    Ok(())
}

pub fn write_or_overwrite(path: impl AsRef<Path>, content: &[u8]) -> Result<()> {
    if let Ok(meta) = std::fs::metadata(&path) {
        if meta.is_dir() {
            return Err(Error::Fs(format!("Dir exists at {:?}", path.as_ref())));
        } else {
            std::fs::remove_file(&path)
                .map_err(|e| Error::Fs(format!("Failed to remove pre-existing file at {e}")))?;
        }
    } else {
        debug!("Creating file {:?}", path.as_ref());
        std::fs::write(&path, content).map_err(|e| {
            Error::Fs(format!(
                "Failed to write content into file {:?}",
                path.as_ref()
            ))
        })?;
    }
    Ok(())
}
