use structopt::StructOpt;

#[derive(Debug, Clone, Eq, PartialEq, StructOpt)]
pub struct DeviceConfig {
    #[structopt(short)]
    pub(crate) root_device: String,
    #[structopt(short)]
    pub(crate) device_name: String,
    #[structopt(short)]
    pub(crate) crypt_device_name: String,
}

impl DeviceConfig {
    pub(crate) fn device_path(&self) -> String {
        format!("/dev/{}", self.device_name)
    }
    pub(crate) fn crypt_device_path(&self) -> String {
        format!("/dev/mapper/{}", self.crypt_device_name)
    }
}

#[derive(Debug, Clone, Eq, PartialEq)]
pub struct InitializedDevice {
    pub(crate) cfg: DeviceConfig,
    pub(crate) device_uuid: String,
    pub(crate) crypt_device_uuid: String,
}

#[derive(Debug, Clone, Eq, PartialEq)]
pub struct Devices {
    pub efi: DeviceConfig,
    pub root: DeviceConfig,
    pub swap: DeviceConfig,
    pub home: DeviceConfig,
}
