use std::io::ErrorKind;
use std::path::{Path, PathBuf};

use tokio::io::AsyncWriteExt;

use crate::error::{Error, Result};
use crate::native_interactions::cmd::run_command;

pub(crate) async fn create_file_if_not_identical_exists(
    path: impl AsRef<Path>,
    content: &[u8],
) -> Result<()> {
    if file_exists(&path).await? {
        match tokio::fs::read(&path).await {
            Ok(file) => {
                if file.as_slice() != content {
                    return match tokio::fs::write(&path, content).await {
                        Ok(_) => Ok(()),
                        Err(e) => Err(Error::FileWriteError(path.as_ref().to_path_buf(), e)),
                    };
                }
            }
            Err(e) => {
                return Err(Error::FileReadError(path.as_ref().to_path_buf(), e));
            }
        }
        Ok(())
    } else {
        match tokio::fs::write(&path, content).await {
            Ok(_) => Ok(()),
            Err(e) => Err(Error::FileWriteError(path.as_ref().to_path_buf(), e)),
        }
    }
}

pub(crate) async fn append_to_file(path: impl AsRef<Path>, content: &[u8]) -> Result<()> {
    match tokio::fs::OpenOptions::new().append(true).open(&path).await {
        Ok(mut file) => match file.write_all(content).await {
            Ok(_) => Ok(()),
            Err(e) => Err(Error::FileWriteError(path.as_ref().to_path_buf(), e)),
        },
        Err(e) => Err(Error::FileWriteError(path.as_ref().to_path_buf(), e)),
    }
}

pub(crate) async fn create_dir_if_not_exists(path: impl AsRef<Path>) -> Result<()> {
    if !file_exists(&path).await? {
        return match tokio::fs::create_dir_all(&path).await {
            Ok(_) => Ok(()),
            Err(e) => Err(Error::FileWriteError(path.as_ref().to_path_buf(), e)),
        };
    }
    Ok(())
}

pub(crate) async fn read_file(target: impl AsRef<Path>) -> Result<String> {
    match tokio::fs::read_to_string(&target).await {
        Ok(s) => Ok(s),
        Err(e) => Err(Error::FileReadError(target.as_ref().to_path_buf(), e)),
    }
}

pub(crate) async fn copy_file(source: impl AsRef<Path>, dest: impl AsRef<Path>) -> Result<()> {
    match tokio::fs::copy(&source, &dest).await {
        Ok(_) => Ok(()),
        Err(e) => Err(Error::FileCopyError(
            source.as_ref().to_path_buf(),
            dest.as_ref().to_path_buf(),
            e,
        )),
    }
}

pub(crate) async fn try_find_file(source: impl AsRef<Path>, name_start: &str) -> Result<PathBuf> {
    match tokio::fs::read_dir(&source).await {
        Ok(mut read_dir) => {
            while let Ok(Some(next)) = read_dir.next_entry().await {
                if let Some(name) = next.file_name().to_str() {
                    if name.starts_with(name_start) {
                        return Ok(next.path());
                    }
                } else {
                    return Err(Error::PathConversionError(format!(
                        "{:?}",
                        next.file_name()
                    )));
                }
            }
            Err(Error::FileNotFoundInDirectory(
                name_start.to_owned(),
                source.as_ref().to_path_buf(),
            ))
        }
        Err(e) => Err(Error::FileReadError(source.as_ref().to_path_buf(), e)),
    }
}

pub(crate) async fn merge_dirs(source: impl AsRef<Path>, dest: impl AsRef<Path>) -> Result<()> {
    if let (Some(src), Some(dest)) = (source.as_ref().to_str(), dest.as_ref().to_str()) {
        run_command("rsync", &["-rb", &format!("{}/", src), dest]).await?;
        Ok(())
    } else {
        Err(Error::PathConversionError(format!(
            "{:?} and {:?}",
            source.as_ref(),
            dest.as_ref()
        )))
    }
}
pub(crate) async fn copy_dir(source: impl AsRef<Path>, dest: impl AsRef<Path>) -> Result<()> {
    if let (Some(src), Some(dest)) = (source.as_ref().to_str(), dest.as_ref().to_str()) {
        run_command("rsync", &["-rb", src, dest]).await?;
        Ok(())
    } else {
        Err(Error::PathConversionError(format!(
            "{:?} and {:?}",
            source.as_ref(),
            dest.as_ref()
        )))
    }
}

async fn file_exists(path: impl AsRef<Path>) -> Result<bool> {
    match tokio::fs::metadata(&path).await {
        Ok(_) => Ok(true),
        Err(e) => {
            if e.kind() == ErrorKind::NotFound {
                Ok(false)
            } else {
                return Err(Error::ReadMetadataError(path.as_ref().to_path_buf(), e));
            }
        }
    }
}
