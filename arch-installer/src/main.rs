use crate::arch::pacstrap_and_enter;
use crate::device::{DeviceConfig, Devices};
use crate::disks::{create_filesystems, init_cryptodisk, mount_disks, open_cryptodisk};
use crate::error::Result;
use crate::process::get_password;
use structopt::StructOpt;

mod arch;
mod device;
mod disks;
mod error;
mod output;
mod parse;
mod process;

#[derive(Debug, StructOpt)]
struct Stage1Config {
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
}

#[derive(Debug, StructOpt)]
enum Installer {
    Stage1(Stage1Config),
}

fn main() -> Result<()> {
    let app = Installer::from_args();
    match app {
        Installer::Stage1(stage_1) => {
            run_stage_1(stage_1)?;
        }
    }
    Ok(())
}

fn run_stage_1(stage_1: Stage1Config) -> Result<()> {
    let efi_config = DeviceConfig {
        root_device: stage_1.efi_device_root,
        device_name: stage_1.efi_device_name,
        crypt_device_name: "".to_owned(),
    };
    let root_config = DeviceConfig {
        root_device: stage_1.root_device_root,
        device_name: stage_1.root_device_name,
        crypt_device_name: stage_1.root_device_crypt_name,
    };
    let home_config = DeviceConfig {
        root_device: stage_1.home_device_root,
        device_name: stage_1.home_device_name,
        crypt_device_name: stage_1.home_device_crypt_name,
    };
    let swap_config = DeviceConfig {
        root_device: stage_1.swap_device_root,
        device_name: stage_1.swap_device_name,
        crypt_device_name: stage_1.swap_device_crypt_name,
    };
    let pwd = get_password()?;
    init_cryptodisk(&root_config, &pwd)?;
    init_cryptodisk(&home_config, &pwd)?;
    init_cryptodisk(&swap_config, &pwd)?;
    open_cryptodisk(&root_config, &pwd)?;
    open_cryptodisk(&home_config, &pwd)?;
    open_cryptodisk(&swap_config, &pwd)?;
    let devices = Devices {
        efi: efi_config,
        root: root_config,
        swap: swap_config,
        home: home_config,
    };
    create_filesystems(&devices)?;
    mount_disks(&devices)?;
    pacstrap_and_enter()?;
    Ok(())
}
