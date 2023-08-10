use alloc::{format, string::String, vec::Vec};
use rusl::platform::STDIN;
use tiny_cli::arg_parse;
use tiny_std::{io::Read, UnixStr};

arg_parse!(
    #[name("Diff files")]
    #[description("Diffs these configuration files against system configuration")]
    #[derive(Copy, Clone, Debug)]
    pub struct DiffCommand {}
);

const CFG_FILE_TUPLES: &[(&UnixStr, &UnixStr)] = &[
    (
        UnixStr::from_str_checked("/home/gramar/code/rust/linux-utils/.xinitrc\0"),
        UnixStr::from_str_checked("/home/gramar/.xinitrc\0"),
    ),
    (
        UnixStr::from_str_checked("/home/gramar/code/rust/linux-utils/.Xresources\0"),
        UnixStr::from_str_checked("/home/gramar/.Xresources\0"),
    ),
    (
        UnixStr::from_str_checked("/home/gramar/code/rust/linux-utils/.gitconfig\0"),
        UnixStr::from_str_checked("/home/gramar/.gitconfig\0"),
    ),
    (
        UnixStr::from_str_checked("/home/gramar/code/rust/linux-utils/.ideavimrc\0"),
        UnixStr::from_str_checked("/home/gramar/.ideavimrc\0"),
    ),
    (
        UnixStr::from_str_checked(
            "/home/gramar/code/rust/linux-utils/.config/lapce-stable/keymaps.toml\0",
        ),
        UnixStr::from_str_checked("/home/gramar/.config/lapce-stable/keymaps.toml\0"),
    ),
    (
        UnixStr::from_str_checked(
            "/home/gramar/code/rust/linux-utils/.config/lapce-stable/settings.toml\0",
        ),
        UnixStr::from_str_checked("/home/gramar/.config/lapce-stable/settings.toml\0"),
    ),
];

impl DiffCommand {
    pub fn run_diff(self) -> Result<(), String> {
        unix_print::unix_println!("[Tiny-helper] Running diff");
        let mut needs_edit = Vec::new();
        for (cfg, sys) in CFG_FILE_TUPLES {
            if let Some(diff_output) = run_sdiff(cfg, sys)? {
                unix_print::unix_println!(
                    "[Tiny-helper] Found diff in {} -> {}",
                    cfg.as_str().unwrap(),
                    sys.as_str().unwrap()
                );
                needs_edit.push(((*cfg, *sys), diff_output));
            }
        }
        for ((cfg, sys), output) in needs_edit {
            unix_print::unix_println!(
                "[Tiny-helper] Left ({}), differs from Right ({}), edit? (y,n)",
                cfg.as_str().unwrap(),
                sys.as_str().unwrap()
            );
            let mut buf = read_stdin_to_newline()?;
            let last = buf.pop().ok_or("Expected y or n, got nothing")?;
            match last {
                b'y' => {
                    unix_print::unix_println!("{output}");
                }
                b'n' => {}
                garbage => return Err(format!("Expected y or n, got: '{}'", garbage as char)),
            }
        }
        Ok(())
    }
}

fn run_sdiff(cfg: &UnixStr, sys: &UnixStr) -> Result<Option<String>, String> {
    let mut child = tiny_std::process::Command::new("/usr/bin/sdiff\0")
        .unwrap()
        .stdout(tiny_std::process::Stdio::MakePipe)
        .arg(cfg)
        .unwrap()
        .arg(sys)
        .unwrap()
        .spawn()
        .map_err(|e| format!("Failed to spawn sdiff: {e}"))?;
    let res = child
        .wait()
        .map_err(|e| format!("Failed to wait for sdiff to complete: {e}"))?;

    match res {
        0 => Ok(None),
        2 => Ok(Some(format!("File {} not found", sys.as_str().unwrap()))),
        code => {
            let mut buf = String::new();
            child
                .stdout
                .unwrap()
                .read_to_string(&mut buf)
                .map_err(|e| format!("Failed to read diff output from child: {e}"))?;
            Ok(Some(buf))
        }
    }
}

fn read_stdin_to_newline() -> Result<Vec<u8>, String> {
    let mut buf = alloc::vec![0u8; 16];
    let mut offset = 0;
    let mut read_bytes = 0;
    let mut f = unsafe { tiny_std::fs::File::from_raw_fd(STDIN) };
    loop {
        let num_read = f
            .read(&mut buf[offset..offset + 16])
            .map_err(|e| format!("Failed to read from stdin: {e}"))?;
        read_bytes += num_read;
        for b in &buf {
            if *b == b'\n' {
                core::mem::forget(f);
                buf.resize(read_bytes - 1, 0);
                return Ok(buf);
            }
        }
        buf.resize(read_bytes + 16, 0);
        unix_print::unix_println!("Reading...");
    }
}
