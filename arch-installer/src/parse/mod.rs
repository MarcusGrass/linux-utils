use crate::error::{Error, Result};

fn get_lsblk_output() -> Result<String> {
    let output = std::process::Command::new("lsblk")
        .arg("-f")
        .output()
        .map_err(|e| Error::ParseDevices(format!("lsblk -f error {e}")))?;
    let output_str = String::from_utf8(output.stdout)
        .map_err(|e| Error::ParseDevices(format!("Failed to convert lsblk output to utf8 {e}")))?;
    Ok(output_str)
}

#[cfg(test)]
mod tests {
    use crate::parse::get_lsblk_output;

    #[test]
    fn get_lsblk() {
        eprintln!("{}", get_lsblk_output().unwrap());
    }

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
        let mut on_target = false;
        for line in example_out.lines() {
            let trimmed = line.trim();
            if line.trim().starts_with("nvme0n1") {
                on_target = true;
                continue;
            }
            if on_target {}
        }
    }
}
