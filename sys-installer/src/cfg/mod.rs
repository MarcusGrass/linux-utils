use crate::error::{Error, Result};
use crate::util::file_system::read_file;
use std::collections::HashMap;
use std::path::Path;

pub const SWAP_FS: &str = "swap";
pub const EXT4_FS: &str = "ext4";
pub const VFAT_FS: &str = "vfat";

pub struct ParsedConfig {
    pub(crate) host_mount_point: String,
    pub(crate) root_dev: ParsedDevice,
    pub(crate) boot_dev: ParsedDevice,
    pub(crate) other_devs: Vec<ParsedDevice>,
    pub(crate) user_name: String,
    pub(crate) host_name: String,
    pub(crate) user_email: String,
    pub(crate) git_user_name: String,
    pub(crate) video_cards: Vec<String>,
    pub(crate) repo: String,
    pub(crate) host_work_dir: String,
    pub(crate) target_work_dir: String,
}

impl ParsedConfig {
    pub async fn parse_from_path(path: impl AsRef<Path>) -> Result<Self> {
        let raw_str = read_file(path).await?;
        let raw_cfg = toml::from_str::<Cfg>(&raw_str)?;
        let root_dev = raw_cfg.devices.root.parse()?;
        let boot_dev = raw_cfg.devices.boot.parse()?;
        let mut other_devs = Vec::new();
        for (_, dev) in raw_cfg.devices.other {
            other_devs.push(dev.parse()?);
        }
        let user_name = raw_cfg.names.user;
        let host_name = raw_cfg.names.host;
        let user_email = raw_cfg.names.email;
        let git_user_name = raw_cfg.names.git_user;
        let video_cards = raw_cfg.video.cards;
        let repo = raw_cfg.repo.address;
        let host_work_dir = raw_cfg.workdirs.host;
        let target_work_dir = raw_cfg.workdirs.target;
        let host_mount_point = raw_cfg.host.mount_point;
        Ok(Self {
            host_mount_point,
            root_dev,
            boot_dev,
            other_devs,
            user_name,
            host_name,
            user_email,
            git_user_name,
            video_cards,
            repo,
            host_work_dir,
            target_work_dir,
        })
    }
}

pub struct ParsedDevice {
    pub(crate) dev: String,
    pub(crate) mount_point: String,
    pub(crate) fs_type: FsType,
}

#[derive(Eq, PartialEq)]
pub enum FsType {
    Ext4,
    Vfat,
    Swap,
}

#[derive(serde::Deserialize, serde::Serialize)]
pub struct Cfg {
    host: Host,
    devices: Devices,
    names: Names,
    video: Video,
    repo: Repo,
    workdirs: WorkDirs,
}
#[derive(serde::Deserialize, serde::Serialize)]
pub struct Host {
    mount_point: String,
}

#[derive(serde::Deserialize, serde::Serialize)]
pub struct Devices {
    pub(crate) root: Device,
    pub(crate) boot: Device,
    pub(crate) other: HashMap<String, Device>,
}

#[derive(serde::Deserialize, serde::Serialize)]
pub struct Device {
    pub(crate) dev: String,
    pub(crate) mount_point: String,
    pub(crate) fs: String,
}

impl Device {
    fn parse(self) -> Result<ParsedDevice> {
        let fs_type = match self.fs.as_str() {
            SWAP_FS => FsType::Swap,
            EXT4_FS => FsType::Ext4,
            VFAT_FS => FsType::Vfat,
            _ => return Err(Error::DeviceParseError(self.dev, self.fs)),
        };
        Ok(ParsedDevice {
            dev: self.dev,
            mount_point: self.mount_point,
            fs_type,
        })
    }
}

#[derive(serde::Deserialize, serde::Serialize)]
pub struct Names {
    pub(crate) user: String,
    pub(crate) host: String,
    pub(crate) email: String,
    pub(crate) git_user: String,
}

#[derive(serde::Deserialize, serde::Serialize)]
pub struct Video {
    pub(crate) cards: Vec<String>,
}

#[derive(serde::Deserialize, serde::Serialize)]
pub struct Repo {
    pub(crate) address: String,
}

#[derive(serde::Deserialize, serde::Serialize)]
pub struct WorkDirs {
    pub(crate) host: String,
    pub(crate) target: String,
}
