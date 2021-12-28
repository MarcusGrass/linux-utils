use structopt::StructOpt;

#[derive(Debug, StructOpt)]
pub(crate) enum Opt {
    Base(BaseInstallOpts),
    ChrootPrep,
    ChrootFinalize,
    CfgRoot,
    CfgUser,
}

#[derive(Debug, StructOpt)]
pub(crate) struct BaseInstallOpts {
    #[structopt(short, long)]
    pub(crate) device: String,
    #[structopt(short, long)]
    pub(crate) mount_point: String,
    #[structopt(short, long)]
    pub(crate) stage_tarball_path: String,
}

pub(crate) struct FsInfo {
    pub(crate) efi: BlockDevice,
    pub(crate) root: BlockDevice,
    pub(crate) swap: Swap,
    pub(crate) home: BlockDevice,
}

impl FsInfo {}

pub(crate) struct BlockDevice {
    pub(crate) mount_point: String,
    pub(crate) name: String,
}

pub(crate) struct Swap {
    pub(crate) name: String,
}

impl BaseInstallOpts {
    pub(crate) fn create_fs_info(&self) -> FsInfo {
        FsInfo {
            efi: BlockDevice {
                name: to_device_name(&self.device, 1),
                mount_point: format!("{}/efi", self.mount_point),
            },
            root: BlockDevice {
                name: to_device_name(&self.device, 2),
                mount_point: format!("{}", self.mount_point),
            },
            swap: Swap {
                name: to_device_name(&self.device, 3),
            },
            home: BlockDevice {
                name: to_device_name(&self.device, 4),
                mount_point: format!("{}/home", self.mount_point),
            },
        }
    }
}

fn to_device_name(device: &str, num: u8) -> String {
    if device.contains("nvme") {
        format!("{}p{}", device, num)
    } else {
        format!("{}{}", device, num)
    }
}
