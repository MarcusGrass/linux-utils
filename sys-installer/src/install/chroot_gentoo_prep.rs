use crate::cfg::ParsedConfig;
use crate::error::Result;
use crate::native_interactions::cmd::{run_command, run_in_dir};
use crate::native_interactions::emerge::{chroot_prep_install_essential, depclean, install_many};
use crate::native_interactions::progress::{default_bar, show_message_then_increment};
use crate::native_interactions::sys_info::{get_string_from_cmd, read_number_from_stdin};
use crate::opt::CfgPath;
use crate::util::file_system::{
    copy_file, create_dir_if_not_exists, create_file_if_not_identical_exists, merge_dirs,
};
use std::os::unix::prelude::CommandExt;
use std::path::PathBuf;

pub(crate) async fn chroot_gentoo_prep(cfg_path: &CfgPath) -> Result<()> {
    let cfg = ParsedConfig::parse_from_path(&cfg_path.cfg).await?;
    let pb = default_bar(10);
    pb.set_message("Emerging webrsync");
    run_command("emerge-webrsync", &[]).await?;
    pb.inc(1);
    pb.set_message("Syncing repos");
    run_command("emerge", &["--sync", "--quiet"]).await?;
    pb.inc(1);
    let out = run_command("eselect", &["profile", "list"]).await?;
    println!("{}", String::from_utf8(out.stdout)?);
    println!("Select profile: ");
    let selected = read_number_from_stdin()?;
    println!("Using profile no {}", selected);
    pb.set_message(format!("Setting profile to {}", selected));
    run_command("eselect", &["profile", "set", &selected.to_string()]).await?;
    pb.inc(1);
    let cmd = "cpuid2cpuflags";
    pb.set_message(format!("Installing {}", cmd));
    pb.inc(1);
    install_many(&[cmd])?;
    pb.set_message("Updating cpu flags");
    create_dir_if_not_exists("/etc/portage/package.use/").await?;
    let flags = get_string_from_cmd(cmd, &[]).await?;
    let content = format!("*/* {}\n", flags);
    create_file_if_not_identical_exists("/etc/portage/package.use/00cpu-flags", content.as_bytes())
        .await?;
    pb.inc(1);
    pb.set_message("Updating world");
    run_command("emerge", &["--update", "--deep", "--newuse", "@world"]).await?;
    pb.inc(1);
    pb.set_message("Cleaning deps");
    depclean()?;
    pb.inc(1);
    pb.set_message("Installing git");
    install_many(&["dev-vcs/git"])?;
    pb.inc(1);
    pb.set_message("Getting system cfg from git");
    git_copy_system_cfg(&cfg).await?;
    pb.inc(1);
    chroot_prep_install_essential()?;
    run_command(
        "ln",
        &[
            "-sf",
            "/usr/share/zoneinfo/Europe/Stockholm",
            "/etc/localtime",
        ],
    )
    .await?;
    pb.set_message("Configuring locale");
    run_command("hwclock", &["--systohc"]).await?;
    show_message_then_increment(
        "Configuring locale".to_owned(),
        futures::future::try_join_all([
            create_file_if_not_identical_exists(
                PathBuf::from("/etc/locale.gen"),
                "en_US.UTF-8 UTF-8\n".as_bytes(),
            ),
            create_file_if_not_identical_exists(
                PathBuf::from("/etc/locale.conf"),
                "LANG=en_US.UTF-8\n".as_bytes(),
            ),
            create_file_if_not_identical_exists(
                PathBuf::from("/etc/vconsole.conf"),
                "KEYMAP=us\n".as_bytes(),
            ),
            create_file_if_not_identical_exists(
                PathBuf::from("/etc/hostname"),
                format!("{}\n", cfg.host_name).as_bytes(),
            ),
        ]),
        &pb,
    )
    .await?;
    run_command("locale-gen", &[]).await?;
    pb.inc(1);
    pb.set_message("Set kernel");
    let out = run_command("eselect", &["kernel", "list"]).await?;
    println!("{}", String::from_utf8(out.stdout)?);
    println!("Select kernel: ");
    let selected = read_number_from_stdin()?;
    run_command("eselect", &["kernel", "set", &selected.to_string()]).await?;
    pb.inc(1);
    pb.finish_with_message("Installed compilation utilities");

    std::process::Command::new("/bin/bash").exec();

    Ok(())
}

async fn git_copy_system_cfg(config: &ParsedConfig) -> Result<()> {
    let build_path = PathBuf::from(&config.target_work_dir);
    create_dir_if_not_exists(&build_path).await?;
    run_in_dir("git", &["clone", &config.repo], &build_path).await?;
    let cfg_dir = &build_path.join("linux-utils");
    merge_dirs(cfg_dir.join("etc"), "/etc").await?;
    copy_file(cfg_dir.join("root_bashrc"), "/root/.bashrc").await?;
    Ok(())
}
