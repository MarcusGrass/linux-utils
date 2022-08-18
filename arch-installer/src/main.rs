use crate::arch::{
    add_to_sudoers, configure_grub, create_hostname, create_hosts, create_user, enable_services,
    install_base_packages, install_rust, install_yay_and_packages, pacstrap_and_enter, set_locale,
    start_pulse, update_pacman_conf,
};
use crate::device::{DeviceConfig, Devices};
use crate::disks::{
    copy_self, copy_user_config, create_filesystems, dump_cfg, generate_keyfiles, init_cryptodisk,
    mount_disks, open_cryptodisk,
};
use crate::error::{Error, Result};
use crate::parse::get_initialized_device_info;
use crate::parse::manipulate::{update_default_grub, update_fstab, update_mkinitcpio};
use crate::process::{await_children, get_password};
use std::path::PathBuf;
use structopt::StructOpt;

mod arch;
mod device;
mod disks;
mod error;
mod output;
mod parse;
mod process;

#[derive(Debug, StructOpt, serde::Deserialize, serde::Serialize)]
pub struct Stage1Config {
    #[structopt(long)]
    efi_device_root: String,
    #[structopt(long)]
    efi_device_name: String,
    #[structopt(long)]
    root_device_root: String,
    #[structopt(long)]
    root_device_name: String,
    #[structopt(long)]
    root_device_crypt_name: String,
    #[structopt(long)]
    home_device_root: String,
    #[structopt(long)]
    home_device_name: String,
    #[structopt(long)]
    home_device_crypt_name: String,
    #[structopt(long)]
    swap_device_root: String,
    #[structopt(long)]
    swap_device_name: String,
    #[structopt(long)]
    swap_device_crypt_name: String,
    disk_pwd: Option<String>,
}

impl Stage1Config {
    fn as_devices(&self) -> Devices {
        Devices {
            efi: DeviceConfig {
                root_device: self.efi_device_root.clone(),
                device_name: self.efi_device_name.clone(),
                crypt_device_name: "".to_string(),
            },
            root: DeviceConfig {
                root_device: self.root_device_root.clone(),
                device_name: self.root_device_name.clone(),
                crypt_device_name: self.root_device_crypt_name.clone(),
            },
            swap: DeviceConfig {
                root_device: self.swap_device_root.clone(),
                device_name: self.swap_device_name.clone(),
                crypt_device_name: self.swap_device_crypt_name.clone(),
            },
            home: DeviceConfig {
                root_device: self.home_device_root.clone(),
                device_name: self.home_device_name.clone(),
                crypt_device_name: self.home_device_crypt_name.clone(),
            },
        }
    }
}

#[derive(Debug, StructOpt)]
struct Stage1Saved {
    cfg_path: PathBuf,
}

impl Stage1Saved {
    fn into_stage_1(self) -> Result<Stage1Config> {
        let bytes = std::fs::read(&self.cfg_path).map_err(|e| {
            Error::Fs(format!(
                "Failed to read saved config from {:?} {e}",
                self.cfg_path
            ))
        })?;
        let parsed = serde_json::from_slice(&bytes).map_err(|e| {
            Error::Parse(format!(
                "Failed to parse file at {:?} into Stage1Config {e}",
                self.cfg_path
            ))
        })?;
        Ok(parsed)
    }
}

#[derive(Debug, StructOpt)]
pub struct Stage2Config {
    username: String,
    hostname: String,
}

#[derive(Debug, StructOpt)]
pub struct Stage3Config {
    username: String,
}

#[allow(clippy::large_enum_variant)]
#[derive(Debug, StructOpt)]
enum Installer {
    Stage1Saved(Stage1Saved),
    Stage1(Stage1Config),
    Stage2(Stage2Config),
    Stage3(Stage3Config),
}

fn main() -> Result<()> {
    let app = Installer::from_args();
    match app {
        Installer::Stage1Saved(saved_path) => {
            run_stage_1(saved_path.into_stage_1()?)?;
        }
        Installer::Stage1(stage_1) => {
            run_stage_1(stage_1)?;
        }
        Installer::Stage2(stage_2) => {
            run_stage_2(stage_2)?;
        }
        Installer::Stage3(stage_3) => {
            run_stage_3(stage_3)?;
        }
    }
    Ok(())
}

fn run_stage_1(mut stage_1: Stage1Config) -> Result<()> {
    let devices = stage_1.as_devices();
    let pwd = get_password()?;
    let root_proc = init_cryptodisk(&devices.root, &pwd)?;
    let home_proc = init_cryptodisk(&devices.home, &pwd)?;
    let swap_proc = init_cryptodisk(&devices.swap, &pwd)?;
    await_children(vec![root_proc, home_proc, swap_proc])?;
    let root_proc = open_cryptodisk(&devices.root, &pwd)?;
    let home_proc = open_cryptodisk(&devices.home, &pwd)?;
    let swap_proc = open_cryptodisk(&devices.swap, &pwd)?;
    await_children(vec![root_proc, home_proc, swap_proc])?;
    create_filesystems(&devices)?;
    mount_disks(&devices)?;
    dump_cfg(&mut stage_1, &pwd)?;
    copy_self()?;
    pacstrap_and_enter()?;
    Ok(())
}

fn run_stage_2(stage_2: Stage2Config) -> Result<()> {
    let stage_1 = Stage1Saved {
        cfg_path: PathBuf::from("/home/stage1.json"),
    }
    .into_stage_1()?;
    let devices = stage_1.as_devices();
    update_pacman_conf()?;
    let pw = &stage_1.disk_pwd.unwrap();
    let keyfiles = generate_keyfiles(&devices, pw)?;
    let devices = get_initialized_device_info(devices.clone())?;
    install_base_packages()?;
    std::thread::scope(|scope| {
        let default_grub = scope.spawn(|| update_default_grub(&devices, &keyfiles));
        let mkinitcpio = scope.spawn(|| update_mkinitcpio(&devices, &keyfiles));
        let fstab = scope.spawn(|| update_fstab(&devices));
        default_grub.join().unwrap()?;
        mkinitcpio.join().unwrap()?;
        fstab.join().unwrap()?;
        Ok(())
    })?;
    std::thread::scope(|scope| {
        let add_user = scope.spawn(|| create_user(&stage_2.username));
        let hostname = scope.spawn(|| create_hostname(&stage_2.hostname));
        let hosts = scope.spawn(create_hosts);
        let locale = scope.spawn(set_locale);
        let sudoers = scope.spawn(|| add_to_sudoers(&stage_2.username));
        let services = scope.spawn(enable_services);
        add_user.join().unwrap()?;
        hostname.join().unwrap()?;
        hosts.join().unwrap()?;
        locale.join().unwrap()?;
        sudoers.join().unwrap()?;
        services.join().unwrap()?;
        Ok(())
    })?;
    configure_grub(&format!("/dev/{}", devices.root.cfg.root_device))?;
    info!("Stage 2 complete, set a root password, a user password for {}, exit chroot, umount -a, then reboot", stage_2.username);
    Ok(())
}

fn run_stage_3(stage_3: Stage3Config) -> Result<()> {
    std::thread::scope(|scope| {
        let install_yay = scope.spawn(install_yay_and_packages);
        let copy =
            scope.spawn(|| copy_user_config(&stage_3.username, "/home/gramar/code/linux-utils"));
        let rust = scope.spawn(install_rust);
        let pulse = scope.spawn(start_pulse);
        install_yay.join().unwrap()?;
        copy.join().unwrap()?;
        rust.join().unwrap()?;
        pulse.join().unwrap()?;
        Ok(())
    })?;
    info!("Done, remember to delete the old config");
    Ok(())
}
