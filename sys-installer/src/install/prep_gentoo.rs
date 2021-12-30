use crate::cfg::ParsedConfig;
use crate::error::Error::PathConversionError;
use crate::error::{Error, Result};
use crate::native_interactions::cmd::{run_command, run_in_dir};
use crate::native_interactions::device::{
    mount_filesystems, mount_pseudo_filesystems, recreate_filesystems, umount,
};
use crate::native_interactions::progress::{default_bar, show_message_then_increment};
use crate::native_interactions::sys_info::get_num_cpus;
use crate::opt::CfgPath;
use crate::util::file_system::{
    append_to_file, copy_file, create_dir_if_not_exists, create_file_if_not_identical_exists,
    try_find_file,
};
use std::os::unix::prelude::CommandExt;
use std::path::PathBuf;

pub(crate) async fn prep_gentoo(cfg_path: &CfgPath) -> Result<()> {
    let pb = default_bar(8);
    pb.set_message("Parsing cfg");
    let parsed_config = ParsedConfig::parse_from_path(&cfg_path.cfg).await?;
    pb.inc(1);
    show_message_then_increment("Unmounting".to_owned(), umount(&parsed_config), &pb).await?;
    show_message_then_increment(
        "Create filesystems".to_owned(),
        recreate_filesystems(&parsed_config),
        &pb,
    )
    .await?;
    show_message_then_increment(
        "Mount filesystems".to_owned(),
        mount_filesystems(&parsed_config),
        &pb,
    )
    .await?;
    show_message_then_increment(
        "Extract stage tarball".to_owned(),
        get_extract_stage_tarball(&parsed_config),
        &pb,
    )
    .await?;
    show_message_then_increment(
        "Create portage conf".to_owned(),
        create_portage_conf(&parsed_config),
        &pb,
    )
    .await?;
    show_message_then_increment(
        "Mount pseudo filesystems".to_owned(),
        mount_pseudo_filesystems(&parsed_config),
        &pb,
    )
    .await?;
    show_message_then_increment(
        "Prep build directory".to_owned(),
        prep_build_dir(&parsed_config, cfg_path),
        &pb,
    )
    .await?;
    pb.finish_with_message("Done preparing, entering chroot");
    enter_chroot(&parsed_config).await?;
    Ok(())
}

async fn get_extract_stage_tarball(config: &ParsedConfig) -> Result<()> {
    let tarball_path = try_find_file(&config.host_work_dir, "stage3").await?;
    let path_as_str = if let Some(p) = tarball_path.to_str() {
        p
    } else {
        return Err(PathConversionError(format!("{:?}", tarball_path)));
    };
    run_in_dir(
        "tar",
        &[
            "xpvf",
            path_as_str,
            "--xattrs-include='*.*'",
            "--numeric-owner",
        ],
        &config.host_mount_point,
    )
    .await?;
    Ok(())
}

async fn create_portage_conf(config: &ParsedConfig) -> Result<()> {
    let flags = "-march=native -O2 -pipe";
    let procs = get_num_cpus().await?;
    let content = format!(
        "\
    CFLAGS=\"{flags}\"\n\
    CXXFLAGS=\"{flags}\"\n\
    MAKEOPTS=\"-j{procs}\"\n\
    EMERGE_DEFAULT_OPTS=\"--jobs {procs}\"\n\
    USE=\"pulseaudio bluetooth -polkit -gnome\"\n\
    ACCEPT_LICENSE=\"*\"\n\
    VIDEO_CARDS=\"{video}\"\n\
    ",
        flags = flags,
        procs = procs,
        video = config.video_cards.join(" ")
    );
    let portage_dir = PathBuf::from(&config.host_mount_point)
        .join("etc")
        .join("portage");
    let make_conf = portage_dir.join("make.conf");
    create_dir_if_not_exists(&portage_dir).await?;
    create_file_if_not_identical_exists(PathBuf::from(&make_conf), content.as_bytes()).await?;
    let mirrors = run_command("mirrorselect", &["-i", "-o"]).await?;
    append_to_file(&make_conf, mirrors.stdout.as_slice()).await?;
    let repos_conf_dir = portage_dir.join("repos.conf");
    create_dir_if_not_exists(&repos_conf_dir).await?;
    copy_file(
        PathBuf::from(&config.host_mount_point)
            .join("usr")
            .join("share")
            .join("portage")
            .join("config")
            .join("repos.conf"),
        repos_conf_dir.join("gentoo.conf"),
    )
    .await?;
    copy_file(
        PathBuf::from("/etc").join("resolv.conf"),
        PathBuf::from(&config.host_mount_point)
            .join("etc")
            .join("resolv.conf"),
    )
    .await?;
    Ok(())
}

async fn prep_build_dir(config: &ParsedConfig, cfg_path: &CfgPath) -> Result<()> {
    let target_build_dir = PathBuf::from(&config.host_mount_point)
        .join(&config.target_work_dir.trim_start_matches("/"));
    create_dir_if_not_exists(&target_build_dir).await?;
    println!("Using build dir {:?}", target_build_dir);
    copy_file(&cfg_path.cfg, target_build_dir.join("install_cfg.toml")).await?;
    Ok(())
}

async fn enter_chroot(config: &ParsedConfig) -> Result<()> {
    let target_build_dir = PathBuf::from(&config.host_mount_point)
        .join(&config.target_work_dir.trim_start_matches("/"));
    match std::env::current_exe() {
        Ok(path) => match &path.file_name().and_then(|s| s.to_str()) {
            Some(name) => {
                copy_file(&path, &target_build_dir.join(name)).await?;
                println!("Chrooting and continuing");
                let mut exec = std::process::Command::new("chroot");
                exec.arg(&config.host_mount_point);
                exec.arg(&format!(".{}/{}", &config.target_work_dir, name));
                exec.arg("chroot-prep");
                exec.arg("-c");
                exec.arg(&format!("{}/install_cfg.toml", &config.target_work_dir));
                exec.exec();
                Ok(())
            }
            None => Err(Error::PathConversionError(format!("{:?}", path))),
        },
        Err(e) => Err(Error::SelfReadError(e)),
    }
}
