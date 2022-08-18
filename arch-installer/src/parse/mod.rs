pub mod manipulate;

use crate::device::{InitializedDevice, InitializedDevices};
use crate::error::{Error, Result};
use crate::{DeviceConfig, Devices};

pub fn get_initialized_device_info(devices: Devices) -> Result<InitializedDevices> {
    let lsblk = get_lsblk_output()?;
    parse_device_uuids(devices, &lsblk)
}

fn get_lsblk_output() -> Result<String> {
    let output = std::process::Command::new("lsblk")
        .arg("-f")
        .output()
        .map_err(|e| Error::Parse(format!("lsblk -f error {e}")))?;
    let output_str = String::from_utf8(output.stdout)
        .map_err(|e| Error::Parse(format!("Failed to convert lsblk output to utf8 {e}")))?;
    Ok(output_str)
}

fn parse_device_uuids(devices: Devices, lsblk: &str) -> Result<InitializedDevices> {
    let (root_uuid, root_crypt_uuid) = parse_dev_uuids(&devices.root, lsblk)?;
    let (home_uuid, home_crypt_uuid) = parse_dev_uuids(&devices.home, lsblk)?;
    let (swap_uuid, swap_crypt_uuid) = parse_dev_uuids(&devices.swap, lsblk)?;
    let (efi_uuid, _) = parse_dev_uuids(&devices.swap, lsblk)?;
    Ok(InitializedDevices {
        efi: InitializedDevice {
            cfg: devices.efi,
            device_uuid: efi_uuid,
            crypt_device_uuid: "".to_string(),
        },
        root: InitializedDevice {
            crypt_device_uuid: root_crypt_uuid.ok_or_else(|| {
                Error::Parse(format!(
                    "Couldn't parse root crypt UUID for device {:?}",
                    &devices.root
                ))
            })?,
            cfg: devices.root,
            device_uuid: root_uuid,
        },
        swap: InitializedDevice {
            crypt_device_uuid: swap_crypt_uuid.ok_or_else(|| {
                Error::Parse(format!(
                    "Couldn't parse swap crypt UUID for device {:?}",
                    &devices.swap
                ))
            })?,
            cfg: devices.swap,
            device_uuid: swap_uuid,
        },
        home: InitializedDevice {
            crypt_device_uuid: home_crypt_uuid.ok_or_else(|| {
                Error::Parse(format!(
                    "Couldn't parse home crypt UUID for device {:?}",
                    &devices.home
                ))
            })?,
            cfg: devices.home,
            device_uuid: home_uuid,
        },
    })
}

fn parse_dev_uuids(device: &DeviceConfig, lsblk: &str) -> Result<(String, Option<String>)> {
    let target_root_device = &device.root_device;
    let mut on_target = false;
    let mut uuid = None;
    let mut crypt_uuid = None;
    for line in lsblk.lines() {
        let trimmed = line.trim();
        if trimmed.starts_with(target_root_device) {
            on_target = true;
            continue;
        } else if on_target && trimmed.contains(&device.device_name) {
            uuid = trimmed
                .split(' ')
                .filter(|s| !s.is_empty())
                .nth(3)
                .map(|s| s.to_string());
            on_target = false;
        } else if !device.crypt_device_name.is_empty()
            && trimmed.contains(&device.crypt_device_name)
        {
            crypt_uuid = trimmed
                .split(' ')
                .filter(|s| !s.is_empty())
                .nth(4)
                .map(|s| s.to_string());
        }
    }
    Ok((
        uuid.ok_or_else(|| Error::Parse(format!("Failed to parse device UUID for {device:?}")))?,
        crypt_uuid,
    ))
}

#[cfg(test)]
mod tests {
    use crate::parse::{get_lsblk_output, parse_dev_uuids};
    use crate::DeviceConfig;

    #[test]
    fn parse_lsblk_out() {
        let example_out = "NAME        FSTYPE      FSVER LABEL UUID                                 FSAVAIL FSUSE% MOUNTPOINTS
sda
├─sda1
├─sda2      vfat        FAT32       B24A-8913                             598.6M     0% /efi
├─sda3      crypto_LUKS 1           19ace206-da6e-42a9-93b7-7df520505be6
│ └─croot   ext4        1.0         42376eb6-0abe-4d00-b416-769a511f116c    4.4G    84% /
├─sda4      crypto_LUKS 2           57c7a3a6-463b-46aa-b7d6-0d19ab838a30
│ └─cswap   swap        1           1f50a69e-d4c2-436c-b6dd-33a409ca71c5                [SWAP]
└─sda5      crypto_LUKS 1           32d761bc-1ee5-4144-973c-3a8c52058fb6
sdb
├─sdb1
└─sdb2      ntfs              Rebar FE4A452F4A44E64D
sdc
└─sdc1      ntfs                    5E366FCD366FA4AD
nvme0n1
├─nvme0n1p1 ntfs                    988ABB988ABB717C
├─nvme0n1p2 vfat        FAT32       B631-2599
├─nvme0n1p3
├─nvme0n1p4 ntfs                    983839BF38399D66
└─nvme0n1p5 ext4        1.0         7fac2e7f-a1b5-4ba6-9d64-f0c5e62bb601     44G    81% /home";
        let device = DeviceConfig {
            root_device: "sda".to_string(),
            device_name: "sda3".to_string(),
            crypt_device_name: "croot".to_string(),
        };
        let (root_uuid, root_crypt_uuid) = parse_dev_uuids(&device, example_out).unwrap();
        assert_eq!("19ace206-da6e-42a9-93b7-7df520505be6", &root_uuid);
        assert_eq!(
            "42376eb6-0abe-4d00-b416-769a511f116c",
            &root_crypt_uuid.unwrap()
        );
        let device = DeviceConfig {
            root_device: "nvme0n1".to_string(),
            device_name: "nvme0n1p5".to_string(),
            crypt_device_name: "".to_string(),
        };
        let (home_uuid, home_crypt_uuid) = parse_dev_uuids(&device, example_out).unwrap();
        assert_eq!("7fac2e7f-a1b5-4ba6-9d64-f0c5e62bb601", &home_uuid);
        assert!(home_crypt_uuid.is_none());
        let device = DeviceConfig {
            root_device: "sda".to_string(),
            device_name: "sda4".to_string(),
            crypt_device_name: "cswap".to_string(),
        };
        let (swap_uuid, swap_crypt_uuid) = parse_dev_uuids(&device, example_out).unwrap();
        assert_eq!("57c7a3a6-463b-46aa-b7d6-0d19ab838a30", &swap_uuid);
        assert_eq!(
            "1f50a69e-d4c2-436c-b6dd-33a409ca71c5",
            &swap_crypt_uuid.unwrap()
        );
        let device = DeviceConfig {
            root_device: "sda".to_string(),
            device_name: "sda2".to_string(),
            crypt_device_name: "".to_string(),
        };
        let (efi_uuid, efi_crypt_uuid) = parse_dev_uuids(&device, example_out).unwrap();
        assert_eq!("B24A-8913", &efi_uuid);
        assert!(efi_crypt_uuid.is_none());
    }
}
