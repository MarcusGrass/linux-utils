use crate::error::{Error, Result};
use crate::native_interactions::cmd::{get_num_cpus, run_command, run_in_dir};
use crate::native_interactions::progress::{default_bar, then_increment};
use crate::opt::BaseInstallOpts;
use crate::util::file_system::{
    append_to_file, copy_file, create_dir_if_not_exists, create_file_if_not_identical_exists,
    read_file,
};
use std::os::unix::prelude::CommandExt;
use std::path::PathBuf;

pub(crate) async fn prep_gentoo(opts: &BaseInstallOpts) -> Result<()> {
    mount_base(opts).await?;
    get_extract_stage_tarball(opts).await?;
    create_portage_conf(opts).await?;
    mount_pseudo(opts).await?;
    enter_chroot(opts).await?;
    Ok(())
}

pub(crate) async fn mount_base(opts: &BaseInstallOpts) -> Result<()> {
    let fs_info = opts.create_fs_info();
    let pb = default_bar(2);
    let mut root_mounted = false;
    pb.println("[1/3] Checking mount points...");
    for line in read_file("/proc/mounts").await?.lines() {
        if line.contains(&fs_info.root.name) {
            root_mounted = true;
        }
    }
    pb.inc(1);
    if root_mounted {
        pb.set_message(format!(
            "unmounting root recursively ({})",
            &fs_info.root.name
        ));
        run_command("umount", &["-R", &fs_info.root.mount_point]).await?;
    }

    let mut swap_on = false;
    for line in read_file("/proc/swaps").await?.lines() {
        if line.contains(&fs_info.swap.name) {
            swap_on = true;
        }
    }

    if swap_on {
        run_command("swapoff", &[&fs_info.swap.name]).await?;
    }
    pb.inc(1);
    pb.finish_with_message("All targets unmounted");
    let pb = default_bar(4);
    pb.println("[2/3] Creating filesystems");
    futures::future::try_join_all([
        then_increment(run_command("mkfs.vfat", &[&fs_info.efi.name]), &pb),
        then_increment(run_command("mkfs.ext4", &["-F", &fs_info.root.name]), &pb),
        then_increment(run_command("mkfs.ext4", &["-F", &fs_info.home.name]), &pb),
        then_increment(run_command("mkswap", &[&fs_info.swap.name]), &pb),
    ])
    .await?;
    pb.finish_with_message("All targets have filesystems");

    let pb = default_bar(6);
    pb.println("[3/3] Mounting devices");
    futures::future::try_join_all([
        then_increment(
            run_command("mount", &[&fs_info.root.name, &fs_info.root.mount_point]),
            &pb,
        ),
        then_increment(run_command("swapon", &[&fs_info.swap.name]), &pb),
    ])
    .await?;
    futures::future::try_join_all([
        then_increment(
            create_dir_if_not_exists(PathBuf::from(&fs_info.home.mount_point)),
            &pb,
        ),
        then_increment(
            create_dir_if_not_exists(PathBuf::from(&fs_info.efi.mount_point)),
            &pb,
        ),
    ])
    .await?;
    futures::future::try_join_all([
        then_increment(
            run_command("mount", &[&fs_info.home.name, &fs_info.home.mount_point]),
            &pb,
        ),
        then_increment(
            run_command("mount", &[&fs_info.efi.name, &fs_info.efi.mount_point]),
            &pb,
        ),
    ])
    .await?;
    pb.finish_with_message("All targets mounted");
    Ok(())
}

async fn get_extract_stage_tarball(opts: &BaseInstallOpts) -> Result<()> {
    let pb = default_bar(1);
    pb.println(format!("[1/1] Extract {:?}", &opts.stage_tarball_path));
    then_increment(
        run_in_dir(
            "tar",
            &[
                "xpvf",
                &opts.stage_tarball_path,
                "--xattrs-include='*.*'",
                "--numeric-owner",
            ],
            &opts.mount_point,
        ),
        &pb,
    )
    .await?;
    pb.finish_with_message("Extracted");
    Ok(())
}

async fn create_portage_conf(opts: &BaseInstallOpts) -> Result<()> {
    println!("Creating configuration files");
    let flags = "-march=native -O2 -pipe";
    let procs = get_num_cpus().await?;
    let content = format!(
        "\
    CFLAGS=\"{flags}\"\n\
    CXXFLAGS=\"{flags}\"\n\
    MAKEOPTS=\"-j{procs}\"\n\
    EMERGE_DEFAULT_OPTS=\"--jobs {procs}\"\n\
    USE=\"pulseaudio bluetooth -policykit -gnome\"\n\
    ACCEPT_LICENSE=\"*\"\n\
    VIDEO_CARDS=\"amdgpu radeonsi\"\n\
    ",
        flags = flags,
        procs = procs,
    );
    let portage_dir = PathBuf::from(&opts.mount_point).join("etc").join("portage");
    let make_conf = portage_dir.join("make.conf");
    println!("Created make conf with {} cores defined", procs);
    create_dir_if_not_exists(&portage_dir).await?;
    create_file_if_not_identical_exists(PathBuf::from(&make_conf), content.as_bytes()).await?;
    println!("Fixing mirrors");
    let mirrors = run_command("mirrorselect", &["-i", "-o"]).await?;
    append_to_file(&make_conf, mirrors.stdout.as_slice()).await?;
    println!("Copying repos conf");
    let repos_conf_dir = portage_dir.join("repos.conf");
    create_dir_if_not_exists(&repos_conf_dir).await?;
    copy_file(
        PathBuf::from(&opts.mount_point)
            .join("usr")
            .join("share")
            .join("portage")
            .join("config")
            .join("repos.conf"),
        repos_conf_dir.join("gentoo.conf"),
    )
    .await?;
    println!("Copying resolv conf");
    copy_file(
        PathBuf::from("/etc").join("resolv.conf"),
        PathBuf::from(&opts.mount_point)
            .join("etc")
            .join("resolv.conf"),
    )
    .await?;
    Ok(())
}

async fn mount_pseudo(opts: &BaseInstallOpts) -> Result<()> {
    println!("Mounting pseudo filesystems");
    futures::future::try_join_all([
        run_command(
            "mount",
            &[
                "--types",
                "proc",
                "/proc",
                &format!("{}/proc", &opts.mount_point),
            ],
        ),
        run_command(
            "mount",
            &["--rbind", "/sys", &format!("{}/sys", &opts.mount_point)],
        ),
        run_command(
            "mount",
            &["--rbind", "/dev", &format!("{}/dev", &opts.mount_point)],
        ),
        run_command(
            "mount",
            &["--bind", "/run", &format!("{}/run", &opts.mount_point)],
        ),
    ])
    .await?;
    futures::future::try_join_all([
        run_command(
            "mount",
            &["--make-rslave", &format!("{}/sys", &opts.mount_point)],
        ),
        run_command(
            "mount",
            &["--make-rslave", &format!("{}/dev", &opts.mount_point)],
        ),
        run_command(
            "mount",
            &["--make-slave", &format!("{}/run", &opts.mount_point)],
        ),
    ])
    .await?;
    Ok(())
}

async fn enter_chroot(opts: &BaseInstallOpts) -> Result<()> {
    let fs_info = opts.create_fs_info();
    let target_build_dir = PathBuf::from(&fs_info.root.mount_point).join("build");
    match std::env::current_exe() {
        Ok(path) => match &path.file_name().and_then(|s| s.to_str()) {
            Some(name) => {
                create_dir_if_not_exists(&target_build_dir).await?;
                copy_file(&path, &target_build_dir.join(name)).await?;
                println!("Chrooting and continuing");
                let mut exec = std::process::Command::new("chroot");
                exec.arg(fs_info.root.mount_point);
                exec.arg(&format!("./build/{}", name));
                exec.arg("chroot-prep");
                exec.exec();
                Ok(())
            }
            None => Err(Error::PathConversionError(format!(
                "file name of {:?}",
                path
            ))),
        },
        Err(e) => Err(Error::SelfReadError(e)),
    }
}
