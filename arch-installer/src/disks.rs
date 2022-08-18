use crate::device::{DeviceConfig, Devices};
use crate::error::{Error, Result};
use crate::process::{run_binary, spawn_binary, ForkedProc};
use crate::{await_children, debug, Stage1Config};
use std::path::{Path, PathBuf};

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
        false,
    )?;
    debug!("Creating ext4 home");
    run_binary(
        "mkfs.ext4",
        vec!["-F", &config.home.crypt_device_path()],
        None,
        false,
    )?;
    debug!("Creating Fat32 efi");
    run_binary(
        "mkfs.fat",
        vec!["-F32", &config.efi.device_path()],
        None,
        false,
    )?;
    debug!("Creating swap");
    run_binary(
        "mkswap",
        vec![&config.swap.crypt_device_path()],
        None,
        false,
    )?;
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
        false,
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
        std::fs::create_dir_all(&path)
            .map_err(|e| Error::Fs(format!("Failed to create dir {:?} {e}", path.as_ref())))?;
    }
    Ok(())
}

pub fn write_or_overwrite(path: impl AsRef<Path>, content: &[u8]) -> Result<()> {
    if let Ok(meta) = std::fs::metadata(&path) {
        if meta.is_dir() {
            return Err(Error::Fs(format!("Dir exists at {:?}", path.as_ref())));
        } else {
            debug!("Overwriting file {:?}", path.as_ref());
            std::fs::write(path, content)
                .map_err(|e| Error::Fs(format!("Failed to write new content at {e}")))?;
        }
    } else {
        debug!("Creating file {:?}", path.as_ref());
        std::fs::write(&path, content).map_err(|e| {
            Error::Fs(format!(
                "Failed to write content into file {:?} {e}",
                path.as_ref()
            ))
        })?;
    }
    Ok(())
}

pub fn dump_cfg(stage_1: &mut Stage1Config, pwd: &str) -> Result<()> {
    stage_1.disk_pwd = Some(pwd.to_string());
    write_or_overwrite(
        "/mnt/home/stage1.json",
        serde_json::to_string(stage_1)
            .map_err(|e| Error::Parse(format!("Failed to serialize stage1 config {e}")))?
            .as_bytes(),
    )
}

pub fn copy_self() -> Result<()> {
    std::fs::copy("/tmp/arch-installer-bin", "/mnt/home/arch-installer-bin")
        .map_err(|e| Error::Fs(format!("Failed to copy self to mounted disk {e}")))?;
    Ok(())
}

pub struct Keyfiles {
    pub root: String,
    pub home: String,
    pub swap: String,
}

pub fn generate_keyfiles(devices: &Devices, pw: &str) -> Result<Keyfiles> {
    debug!("Generating keyfiles");
    ensure_dir_or_try_create("/root")?;
    ensure_dir_or_try_create("/etc/cryptsetup-keys.d")?;
    let root_keyfile = "/root/croot.keyfile".to_owned();
    generate_keyfile(&devices.root.device_path(), &root_keyfile, pw)?;
    let home_keyfile = "/etc/cryptsetup-keys.d/home.key".to_owned();
    let home_key_path = devices.home.device_path();
    let swap_keyfile = "/etc/cryptsetup-keys.d/swap.key".to_owned();
    let swap_key_path = devices.swap.device_path();
    std::thread::scope(|scope| {
        let res = scope.spawn(|| generate_keyfile(&home_key_path, &home_keyfile, pw));
        let res2 = scope.spawn(|| generate_keyfile(&swap_key_path, &swap_keyfile, pw));
        res.join().unwrap()?;
        res2.join().unwrap()
    })?;
    debug!("Generated keyfiles");

    Ok(Keyfiles {
        root: root_keyfile,
        home: home_keyfile,
        swap: swap_keyfile,
    })
}

fn generate_keyfile(label: &str, path: impl AsRef<Path>, pw: &str) -> Result<()> {
    debug!("Creating cryptkey for {label}");
    run_binary(
        "dd",
        vec![
            "bs=512",
            "count=4",
            "if=/dev/random",
            &format!("of={:?}", path.as_ref()),
            "iflag=fullblock",
        ],
        None,
        false,
    )?;
    run_binary(
        "chmod",
        vec!["000", &format!("{:?}", path.as_ref())],
        None,
        false,
    )?;
    debug!("Adding luksKey for {label}");
    run_binary(
        "cryptsetup",
        vec!["-v", "luksAddKey", label, &format!("{:?}", path.as_ref())],
        Some(pw),
        false,
    )?;
    debug!("Key added for {label}");
    Ok(())
}

struct ConfigSpec {
    relative_source: String,
    abs_target: String,
}

impl ConfigSpec {
    fn replace(&self, cfg_dir: impl AsRef<Path>) -> Result<()> {
        let pb = PathBuf::from(cfg_dir.as_ref()).join(&self.relative_source);
        let parent = pb.parent().ok_or_else(|| {
            Error::Fs(format!(
                "Could not find parent dir to relative source {pb:?}"
            ))
        })?;
        ensure_dir_or_try_create(parent)?;
        let tgt = PathBuf::from(&self.abs_target);
        let tgt_parent = tgt.parent().ok_or_else(|| {
            Error::Fs(format!(
                "Could not find parent dir to absolute destination {tgt:?}"
            ))
        })?;
        ensure_dir_or_try_create(tgt_parent)?;
        std::fs::copy(&pb, &tgt)
            .map_err(|e| Error::Fs(format!("Failed to copy {:?} to {:?} {e}", pb, tgt)))?;
        Ok(())
    }
}

pub fn copy_user_config(username: &str, cfg_dir: &str) -> Result<()> {
    let base_dirs = [
        "/pictures/screenshots",
        "/pictures/wps",
        "/code/java",
        "/code/python",
        "/code/bash",
        "/code/rust",
        "/code/unclassified",
        "/documents",
        "/downloads/",
        "/misc",
    ];
    for dir in base_dirs {
        ensure_dir_or_try_create(&format!("/home/{}{}", username, dir))?;
    }
    run_binary(
        "git",
        vec![
            "clone",
            "https://github.com/MarcusGrass/linux-utils.git",
            cfg_dir,
        ],
        None,
        false,
    )?;
    let gitconfig = ".gitconfig";
    let xprofile = ".xprofile";
    let xinitrc = ".xinitrc";
    let alacritty_yml = ".config/alacritty/alacritty.yml";
    let dunst = ".config/dunst/dunstrc";
    let gnupg = ".gnupg/gpg-agent.conf";
    let ssh = ".ssh/config";
    let configs = [
        ConfigSpec {
            relative_source: gitconfig.to_string(),
            abs_target: format!("/home/{}/{}", username, gitconfig),
        },
        ConfigSpec {
            relative_source: xprofile.to_string(),
            abs_target: format!("/home/{}/{}", username, xprofile),
        },
        ConfigSpec {
            relative_source: xinitrc.to_string(),
            abs_target: format!("/home/{}/{}", username, xinitrc),
        },
        ConfigSpec {
            relative_source: alacritty_yml.to_string(),
            abs_target: format!("/home/{}/{}", username, alacritty_yml),
        },
        ConfigSpec {
            relative_source: dunst.to_string(),
            abs_target: format!("/home/{}/{}", username, dunst),
        },
        ConfigSpec {
            relative_source: gnupg.to_string(),
            abs_target: format!("/home/{}/{}", username, gnupg),
        },
        ConfigSpec {
            relative_source: ssh.to_string(),
            abs_target: format!("/home/{}/{}", username, ssh),
        },
    ];

    std::thread::scope(|scope| {
        let mut handles = vec![];
        for config in &configs {
            handles.push(scope.spawn(|| config.replace(&cfg_dir)));
        }
        for handle in handles {
            handle.join().unwrap()?;
        }
        Ok(())
    })?;
    Ok(())
}
