use crate::cfg::ParsedConfig;
use crate::error::{Error, Result};
use crate::native_interactions::cmd::{run_command, run_in_dir};
use crate::native_interactions::progress::{default_bar, show_message_then_increment};
use crate::native_interactions::sys_info::get_string_from_cmd;
use crate::opt::CfgPath;
use crate::util::file_system::{copy_dir, copy_file, create_dir_if_not_exists};
use std::path::{Path, PathBuf};

pub(crate) async fn user_configure_system(path: &CfgPath) -> Result<()> {
    let cfg = ParsedConfig::parse_from_path(&path.cfg).await?;
    let user = get_string_from_cmd("whoami", &[]).await?;
    if user != cfg.user_name {
        return Err(Error::BadUserError);
    }
    let base = PathBuf::from("/home").join(&user);
    println!("Running for user {}", &user);
    create_dirs(&base).await?;
    git_copy_conf(&base).await?;
    generate_rsa_keys(&cfg).await?;
    update_git_conf(&cfg).await?;
    start_systemd_user_services().await?;

    Ok(())
}

async fn create_dirs(base: impl AsRef<Path>) -> Result<()> {
    let pb = default_bar(14);
    let code = base.as_ref().join("code");
    let pictures = base.as_ref().join("pictures");
    futures::future::try_join_all([
        show_message_then_increment("code".to_owned(), create_dir_if_not_exists(&code), &pb),
        show_message_then_increment(
            "pictures".to_owned(),
            create_dir_if_not_exists(&pictures),
            &pb,
        ),
        show_message_then_increment(
            "downloads".to_owned(),
            create_dir_if_not_exists(&base.as_ref().join("downloads")),
            &pb,
        ),
        show_message_then_increment(
            "misc".to_owned(),
            create_dir_if_not_exists(&base.as_ref().join("misc")),
            &pb,
        ),
        show_message_then_increment(
            "pictures".to_owned(),
            create_dir_if_not_exists(&base.as_ref().join("pictures")),
            &pb,
        ),
        show_message_then_increment(
            "documents".to_owned(),
            create_dir_if_not_exists(&base.as_ref().join("documents")),
            &pb,
        ),
    ])
    .await?;
    futures::future::try_join_all([
        show_message_then_increment(
            "code/rust".to_owned(),
            create_dir_if_not_exists(code.join("rust")),
            &pb,
        ),
        show_message_then_increment(
            "code/java".to_owned(),
            create_dir_if_not_exists(code.join("java")),
            &pb,
        ),
        show_message_then_increment(
            "code/python".to_owned(),
            create_dir_if_not_exists(code.join("python")),
            &pb,
        ),
        show_message_then_increment(
            "code/c".to_owned(),
            create_dir_if_not_exists(code.join("c")),
            &pb,
        ),
        show_message_then_increment(
            "code/cxx".to_owned(),
            create_dir_if_not_exists(code.join("cxx")),
            &pb,
        ),
        show_message_then_increment(
            "code/unclassified".to_owned(),
            create_dir_if_not_exists(code.join("unclassified")),
            &pb,
        ),
        show_message_then_increment(
            "pictures/wps".to_owned(),
            create_dir_if_not_exists(pictures.join("wps")),
            &pb,
        ),
        show_message_then_increment(
            "pictures/screenshots".to_owned(),
            create_dir_if_not_exists(pictures.join("screenshots")),
            &pb,
        ),
    ])
    .await?;
    pb.finish_with_message("Created user directories");
    Ok(())
}

async fn git_copy_conf(base: impl AsRef<Path>) -> Result<()> {
    let pb = default_bar(8);
    let code = base.as_ref().join("code");
    show_message_then_increment(
        "Ensure code directory exists".to_owned(),
        create_dir_if_not_exists(&code),
        &pb,
    )
    .await?;
    show_message_then_increment(
        "Clone linux-utils repo".to_owned(),
        run_in_dir(
            "git",
            &["clone", "https://github.com/MarcusGrass/linux-utils.git"],
            &code,
        ),
        &pb,
    )
    .await?;
    let cfg_dir = &code.join("linux-utils");
    show_message_then_increment(
        "Copying .config".to_owned(),
        copy_dir(cfg_dir.join(".config"), &base),
        &pb,
    )
    .await?;
    show_message_then_increment(
        "Copying .gnupg".to_owned(),
        copy_dir(cfg_dir.join(".gnupg"), &base),
        &pb,
    )
    .await?;
    show_message_then_increment(
        "Copying .ssh".to_owned(),
        copy_dir(cfg_dir.join(".ssh"), &base),
        &pb,
    )
    .await?;
    show_message_then_increment(
        "Copying .bashrc".to_owned(),
        copy_file(cfg_dir.join(".bashrc"), &base.as_ref().join(".bashrc")),
        &pb,
    )
    .await?;
    show_message_then_increment(
        "Copying .xinitrc".to_owned(),
        copy_file(cfg_dir.join(".xinitrc"), &base.as_ref().join(".xinitrc")),
        &pb,
    )
    .await?;
    show_message_then_increment(
        "Copying .xprofile".to_owned(),
        copy_file(cfg_dir.join(".xprofile"), &base.as_ref().join(".xprofile")),
        &pb,
    )
    .await?;
    pb.finish_with_message("Copied user settings");
    Ok(())
}

async fn generate_rsa_keys(cfg: &ParsedConfig) -> Result<()> {
    run_command(
        "ssh-keygen",
        &[
            "-t",
            "rsa",
            "-b",
            "4096",
            "-C",
            &cfg.user_email,
            "-f",
            &format!("/home/{}/.ssh/id_rsa", cfg.user_name),
            "-N",
        ],
    )
    .await?;
    Ok(())
}

async fn update_git_conf(cfg: &ParsedConfig) -> Result<()> {
    run_command(
        "git",
        &["config", "--global", "user.email", &cfg.user_email],
    )
    .await?;
    run_command(
        "git",
        &["config", "--global", "user.name", &cfg.git_user_name],
    )
    .await?;
    run_command("git", &["config", "--global", "pull.rebase", "true"]).await?;
    run_command("git", &["config", "--global", "push.default", "current"]).await?;
    run_command("git", &["config", "--global", "rerere.enabled", "true"]).await?;
    run_command("git", &["config", "--global", "init.defaultBranch", "main"]).await?;
    Ok(())
}

async fn start_systemd_user_services() -> Result<()> {
    run_command(
        "systemctl",
        &[
            "--user",
            "enable",
            "pulseaudio.service",
            "pulseaudio.socket",
        ],
    )
    .await?;
    Ok(())
}
