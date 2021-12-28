use crate::error::Result;
use crate::native_interactions::cmd::run_command;
use crate::native_interactions::emerge::chroot_finalize_install_essential;
use crate::native_interactions::progress::{default_bar, show_message_then_increment};
use std::os::unix::prelude::CommandExt;

pub(crate) async fn chroot_gentoo_finalize() -> Result<()> {
    let pb = default_bar(3);
    show_message_then_increment(
        "Running grub install".to_owned(),
        run_command(
            "grub-install",
            &[
                "--target=x86_64-efi",
                "--efi-directory=/efi",
                "--bootloader-id=GRINUX",
            ],
        ),
        &pb,
    )
    .await?;
    show_message_then_increment(
        "Generating vanilla initramfs".to_owned(),
        run_command(
            "genkernel",
            &[
                "--install",
                "--kernel-config=/usr/src/linux/.config",
                "initramfs",
            ],
        ),
        &pb,
    )
    .await?;
    show_message_then_increment(
        "Creating grub cfg".to_owned(),
        run_command("grub-mkconfig", &["-o", "/boot/grub/grub.cfg"]),
        &pb,
    )
    .await?;
    pb.finish_with_message("Configured bootloader");
    chroot_finalize_install_essential()?;

    println!("Set root passwd, then create an /etc/fstab, reboot, and continue");
    std::process::Command::new("/bin/passwd").exec();
    Ok(())
}
