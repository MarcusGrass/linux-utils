use crate::disks::{ensure_dir_or_try_create, write_or_overwrite};
use crate::error::Result;
use crate::process::run_binary;
use crate::{debug, Error};
use std::fmt::Write;
use std::os::unix::process::CommandExt;

pub fn pacstrap_and_enter() -> Result<()> {
    debug!("Running pacstrap");
    run_binary(
        "pacstrap",
        vec!["/mnt", "base", "base-devel", "linux", "linux-firmware"],
        None,
        true,
    )?;
    debug!("Generating fstab");
    let fstab = run_binary("genfstab", vec!["-U", "-p", "/mnt"], None, false)?;
    debug!("Writing fstab");
    write_or_overwrite("/mnt/etc/fstab", fstab.stdout.as_ref())?;
    debug!("Entering arch-chroot");
    std::process::Command::new("arch-chroot")
        .arg("/mnt")
        .arg("/bin/bash")
        .arg("-c")
        .arg("/home/arch-installer-bin stage2 /home/stage2.json")
        .exec();
    Ok(())
}

pub fn create_user(username: &str) -> Result<()> {
    run_binary("useradd", vec!["-m", username], None, false)?;
    debug!("Added user {username}");
    Ok(())
}

pub fn create_hostname(hostname: &str) -> Result<()> {
    write_or_overwrite("/etc/hostname", hostname.as_bytes())?;
    debug!("Created and populated /etc/hostname");
    Ok(())
}

pub fn create_hosts() -> Result<()> {
    write_or_overwrite(
        "/etc/hosts",
        "127.0.0.1\tlocalhost\n::1\tlocalhost\n".as_bytes(),
    )?;
    debug!("Created and populated /etc/hosts");
    Ok(())
}

pub fn partial_set_locale() -> Result<()> {
    std::thread::scope(|scope| {
        let append = scope.spawn(append_default_locale);
        let set = scope.spawn(set_locale_conf);
        append.join().unwrap()?;
        set.join().unwrap()
    })?;
    run_binary("locale-gen", vec![], None, false)?;
    run_binary(
        "ln",
        vec![
            "-s",
            "/usr/share/zoneinfo/Europe/Stockholm",
            "/etc/localtime",
        ],
        None,
        false,
    )?;
    debug!("Partially generated locale");
    Ok(())
}

pub fn finalize_set_locale() -> Result<()> {
    run_binary(
        "timedatectl",
        vec!["set-timezone", "Europe/Stockholm"],
        None,
        false,
    )?;
    run_binary("hwclock", vec!["--systohc", "--utc"], None, false)?;
    debug!("Generated locale and set hardware clock");
    Ok(())
}

#[allow(clippy::format_push_string)]
fn append_default_locale() -> Result<()> {
    let mut content = std::fs::read_to_string("/etc/locale.gen")
        .map_err(|e| Error::Fs(format!("Failed to read /etc/locale.gen {e}")))?;
    content.push_str(&format!("{content}\nen_US.UTF-8 UTF-8\n"));
    write_or_overwrite("/etc/locale.gen", content.as_bytes())
}

fn set_locale_conf() -> Result<()> {
    write_or_overwrite("/etc/locale.conf", "LANG=en_US.UTF-8".as_bytes())
}

pub fn add_to_sudoers(username: &str) -> Result<()> {
    let mut content = std::fs::read_to_string("/etc/sudoers")
        .map_err(|e| Error::Fs(format!("Failed to read /etc/sudoers {e}")))?;
    let _ = content.write_fmt(format_args!("{}    ALL=(ALL) NOPASSWD:ALL\n", username));
    std::fs::write("/etc/sudoers", content.as_bytes())
        .map_err(|e| Error::Fs(format!("Failed to write to /etc/sudoers {e}",)))?;
    debug!("Added {username} to sudoers");
    Ok(())
}

pub fn enable_services() -> Result<()> {
    run_binary(
        "sudo",
        vec![
            "systemctl",
            "enable",
            "--now",
            "iwd",
            "dhcpcd",
            "bluetooth",
            "ntpd",
        ],
        None,
        false,
    )?;
    debug!("Enabled services");
    Ok(())
}

pub fn update_pacman_conf() -> Result<()> {
    let content = std::fs::read_to_string("/etc/pacman.conf")
        .map_err(|e| Error::Fs(format!("Failed to read /etc/pacman.conf {e}")))?;
    let mut on_multilib = false;
    let mut new_content = String::new();
    for line in content.lines() {
        if line.trim().starts_with("#[multilib]") {
            on_multilib = true;
            let _ = new_content.write_fmt(format_args!("[multilib]\n"));
        } else if on_multilib {
            let _ = new_content.write_fmt(format_args!("{}\n", line.replace('#', "")));
            on_multilib = false;
        } else if line.trim().starts_with("#ParallelDownloads") {
            let _ = new_content.write_fmt(format_args!("ParallelDownloads = 50\n"));
        } else {
            let _ = new_content.write_fmt(format_args!("{line}\n"));
        }
    }
    write_or_overwrite("/etc/pacman.conf", new_content.as_bytes())?;
    debug!("Updated /etc/pacman.conf");
    run_binary("pacman", vec!["-Syyuu"], None, true)?;
    Ok(())
}

pub fn install_base_packages() -> Result<()> {
    run_binary(
        "pacman",
        vec![
            "-S",
            // Boot
            "grub",
            "efibootmgr",
            "sudo",
            "iwd",
            "dhcpcd",
            // Base
            "sudo",
            "cronie",
            "ntp",
            "unzip",
            "gcc",
            "linux-headers",
            "openssh",
            "openssl",
            "gnupg",
            "gnome-keyring",
            "bash-completion",
            "neovim",
            "python",
            "python-pip",
            "git",
            "bluez-utils",
            "pulseaudio",
            "pulseaudio-bluetooth",
            "pulseaudio-alsa",
            "pavucontrol",
            "pass",
            "os-prober",
            "docker",
            "docker-compose",
            "dnsutils",
            "netcat",
            // WM stuff
            "alacritty",
            "xorg-server",
            "dmenu",
            "dunst",
            "xorg-xinit",
            "xorg-xinput",
            "xorg-xrandr",
            "xscreensaver",
            "xclip",
            "maim",
            "feh",
            "pinta",
            "redshift",
            "papirus-icon-theme",
            "otf-font-awesome",
            "ttf-ubuntu-font-family",
            // Programming
            "rustup",
            "lld",
            "clang",
            "jdk11-openjdk",
            "openjdk11-src",
            "maven",
            "dbeaver",
            // Misc
            "discord",
            "--noconfirm",
        ],
        None,
        true,
    )?;
    debug!("Installed base packages");
    Ok(())
}

pub fn install_yay_and_packages() -> Result<()> {
    install_yay()?;
    install_yay_packages()
}

fn install_yay() -> Result<()> {
    let tmp_yay = "/tmp/yay";
    ensure_dir_or_try_create(tmp_yay)?;
    run_binary(
        "git",
        vec!["clone", "https://aur.archlinux.org/yay.git", tmp_yay],
        None,
        false,
    )?;
    let res = run_binary(
        "bash",
        vec!["-c", &format!("cd {tmp_yay} && makepkg -si --noconfirm")],
        None,
        false,
    );
    std::fs::remove_dir_all(tmp_yay)
        .map_err(|e| Error::Fs(format!("Failed to clean up {tmp_yay} {e}")))?;
    res?;
    debug!("Installed yay");
    Ok(())
}

fn install_yay_packages() -> Result<()> {
    run_binary(
        "yay",
        vec!["spotify", "steam", "slack-desktop", "clion", "clion-jre"],
        None,
        true,
    )?;
    debug!("Installed yay packages");
    Ok(())
}

pub fn start_pulse() -> Result<()> {
    run_binary("pulseaudio", vec!["-D"], None, false)?;
    debug!("Started pulse");
    Ok(())
}

pub fn install_rust() -> Result<()> {
    run_binary("rustup", vec!["toolchain", "install", "stable"], None, true)?;
    debug!("Installed rust");
    Ok(())
}

pub fn configure_grub() -> Result<()> {
    debug!("Configuring grub");
    run_binary(
        "grub-install",
        vec![
            "--target=x86_64-efi",
            "--efi-directory=/efi",
            "--bootloader-id=GRUB",
            "--recheck",
        ],
        None,
        false,
    )?;
    run_binary("mkinitcpio", vec!["-P"], None, true)?;
    run_binary(
        "grub-mkconfig",
        vec!["-o", "/boot/grub/grub.cfg"],
        None,
        false,
    )?;
    debug!("Grub configured");
    Ok(())
}
