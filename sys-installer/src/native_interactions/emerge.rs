use std::process::Stdio;

use crate::error::{Error, Result};

pub(crate) fn install_many(pkgs: &[&str]) -> Result<()> {
    let mut cmd = std::process::Command::new("emerge");
    cmd.args(pkgs);
    cmd.stdout(Stdio::inherit());
    cmd.stderr(Stdio::inherit());
    match cmd.spawn() {
        Ok(mut child) => {
            if let Ok(exit) = child.wait() {
                if exit.success() {
                    Ok(())
                } else {
                    Err(Error::CommandExitError(format!("{:?}", cmd)))
                }
            } else {
                Err(Error::CommandExitError(format!("{:?}", cmd)))
            }
        }
        Err(e) => Err(Error::CommandStartError(format!("{:?}", cmd), e)),
    }
}

pub(crate) fn chroot_prep_install_essential() -> Result<()> {
    let pgks = [
        "app-editors/neovim",
        "sys-kernel/linux-firmware",
        "sys-kernel/gentoo-sources",
        "sys-apps/pciutils",
        "sys-devel/clang",
        "sys-devel/llvm",
        "sys-devel/lld",
        "sys-boot/grub",
        "sys-kernel/genkernel",
    ];
    install_many(pgks.as_slice())?;
    Ok(())
}
pub(crate) fn chroot_finalize_install_essential() -> Result<()> {
    let pgks = ["net-misc/dhcpcd", "net-wireless/iwd"];
    install_many(pgks.as_slice())?;
    Ok(())
}
pub(crate) fn root_stage_install_essential() -> Result<()> {
    let pgks = [
        "app-portage/gentoolkit",
        "app-portage/layman",
        "app-admin/doas",
        "net-misc/ntp",
        "net-analyzer/netcat",
        "app-shells/bash-completion",
        "app-admin/pass",
        "app-containers/docker",
        "app-containers/docker-compose",
        "dev-vcs/git",
        "sys-power/cpupower",
        "x11-base/xorg-x11",
        "x11-terms/alacritty",
        "x11-misc/dmenu",
        "x11-misc/dunst",
        "x11-misc/xclip",
        "x11-misc/arandr",
        "x11-misc/autorandr",
        "x11-misc/redshift",
        "media-gfx/maim",
        "media-gfx/feh",
        "media-gfx/xpaint",
        "media-sound/spotify",
        "net-im/discord-bin",
        "net-im/slack",
        //"dev-util/idea-ultimate", get from custom overlay later
        "www-client/google-chrome",
        "net-wireless/blueman",
        "media-fonts/source-pro",
    ];
    install_many(&pgks)?;
    Ok(())
}
