use crate::device::InitializedDevices;
use crate::disks::{ensure_dir_or_try_create, Keyfiles};
use crate::error::Result;
use crate::{debug, Error};
use std::fmt::Write;

pub fn update_default_grub(devices: &InitializedDevices, keyfiles: &Keyfiles) -> Result<()> {
    let default_grub = "/etc/default/grub";
    let content = std::fs::read_to_string(default_grub)
        .map_err(|e| Error::Fs(format!("Failed to read {default_grub} {e}")))?;
    let mut new_content = String::new();
    let cryptdevice_str = format!(
        "cryptdevice=UUID={}:{} ",
        devices.root.device_uuid, devices.root.cfg.crypt_device_name
    );
    let root_str = format!("root={:?} ", devices.root.cfg.crypt_device_path());
    let root_crypt_key = format!("cryptkey=rootfs:/root/{} ", keyfiles.root);
    let resume = &format!("{} ", devices.swap.cfg.crypt_device_path());
    for line in content.lines() {
        if line.starts_with("GRUB_CMDLINE_LINUX=") {
            let trimmed = line.trim();
            let mut no_start = trimmed.replace("GRUB_CMDLINE_LINUX=\"", "");
            if !no_start.contains(&root_crypt_key) {
                no_start.insert_str(0, &root_crypt_key);
            }
            if !no_start.contains(&root_str) {
                no_start.insert_str(0, &root_str);
            }
            if !no_start.contains(&cryptdevice_str) {
                no_start.insert_str(0, &cryptdevice_str);
            }
            let _ = new_content.write_fmt(format_args!("GRUB_CMDLINE_LINUX\"{}\n", no_start));
            continue;
        } else if line.starts_with("GRUB_CMDLINE_LINUX_DEFAULT=") {
            let mut no_start = line.trim().replace("GRUB_CMDLINE_LINUX_DEFAULT=\"", "");
            if !no_start.contains(resume) {
                no_start.insert_str(0, resume);
            }
            let _ =
                new_content.write_fmt(format_args!("GRUB_CMDLINE_LINUX_DEFAULT=\"{}\n", no_start));
            continue;
        } else if line.starts_with("#GRUB_ENABLE_CRYPTODISK") {
            new_content.push_str("GRUB_ENABLE_CRYPTODISK=y\n");
        } else {
            let _ = new_content.write_fmt(format_args!("{line}\n"));
        }
    }
    std::fs::write(default_grub, new_content.as_bytes())
        .map_err(|e| Error::Fs(format!("Failed to dump new cfg to {} {e}", default_grub)))?;
    debug!("Updated /etc/default/grub");
    Ok(())
}

pub fn update_mkinitcpio(devices: &InitializedDevices, keyfiles: &Keyfiles) -> Result<()> {
    let hooks = "/etc/initcpio/hooks/openswap";
    let install = "/etc/initcpio/install/openswap";
    ensure_dir_or_try_create("/etc/initcpio/hooks")?;
    ensure_dir_or_try_create("/etc/initcpio/install")?;
    let hooks_content = format!(
        "run_hook() 
{{
    ## Optional: To avoid race conditions
    x=0;
    while [ ! -b {} ] && [ $x -le 10 ]; do
       x=$((x+1))
       sleep .2
    done
    ## End of optional

    mkdir crypto_key_device
    mount {} crypto_key_device
    cryptsetup open --key-file crypto_key_device/{} {} {}
    umount crypto_key_device
}}",
        devices.root.cfg.crypt_device_path(),
        devices.root.cfg.crypt_device_path(),
        keyfiles.swap,
        devices.swap.cfg.device_path(),
        devices.swap.cfg.crypt_device_name
    );
    std::fs::write(hooks, hooks_content.as_bytes())
        .map_err(|e| Error::Fs(format!("Failed to write swap open hook to {} {e}", hooks)))?;
    debug!("Wrote mkinitcpio hibernate hook");
    let install_content = format!(
        "build ()
{{
    add_runscript
}}
help ()
{{
cat<<HELPEOF
  This opens the swap encrypted partition {} in {}
HELPEOF
}}",
        devices.swap.cfg.device_path(),
        devices.swap.cfg.crypt_device_path()
    );

    std::fs::write(install, install_content.as_bytes()).map_err(|e| {
        Error::Fs(format!(
            "Failed to write swap install hook to {} {e}",
            install
        ))
    })?;
    debug!("Wrote mkinitcpio hibernate install");
    let mkinitcpio = "/etc/mkinitcpio.conf";
    let content = std::fs::read_to_string(mkinitcpio)
        .map_err(|e| Error::Fs(format!("Failed to read {} {e}", mkinitcpio)))?;
    let mut new_content = String::new();
    for line in content.lines() {
        if line.starts_with("FILES=") {
            let _ = new_content.write_fmt(format_args!("FILES=({})\n", keyfiles.root));
        } else if line.starts_with("HOOKS=") {
            let tokens = [
                "keyboard",
                "fsck",
                "keymap",
                "encrypt",
                "openswap",
                "resume",
                "filesystems",
            ];
            let mut line_content = line.trim().to_string();
            for token in tokens {
                line_content = line_content.replace(&format!("{token} "), "");
            }
            // Remove trailing )
            line_content.remove(line_content.len() - 1);
            for (idx, token) in tokens.into_iter().enumerate() {
                if idx == tokens.len() - 1 {
                    let _ = line_content.write_fmt(format_args!("{})\n", token));
                } else {
                    let _ = line_content.write_fmt(format_args!("{} ", token));
                }
            }
            new_content.push_str(&line_content);
        }
    }
    std::fs::write(mkinitcpio, new_content.as_bytes())
        .map_err(|e| Error::Fs(format!("Failed to write new content to {} {e}", mkinitcpio)))?;
    debug!("Wrote mkinitcpio config");
    Ok(())
}

pub fn update_fstab(devices: &InitializedDevices) -> Result<()> {
    let fstab = "/etc/fstab";
    let mut content = std::fs::read_to_string(fstab)
        .map_err(|e| Error::Fs(format!("Failed to read fstab from {fstab} {e}")))?;
    let _ = content.write_fmt(format_args!(
        "{}\tswap\tswap\tdefaults\t0 0\n",
        devices.swap.cfg.crypt_device_path()
    ));
    std::fs::write(fstab, content.as_bytes())
        .map_err(|e| Error::Fs(format!("failed to write new content to {} {e}", fstab)))?;
    debug!("Updated /etc/fstab");
    Ok(())
}
