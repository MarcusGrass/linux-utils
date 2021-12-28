use std::path::PathBuf;
use std::string::FromUtf8Error;

pub type Result<T> = std::result::Result<T, Error>;

#[derive(thiserror::Error, Debug)]
pub enum Error {
    #[error("Tried to run as root su user then re-run")]
    BadUserError,
    #[error("Failed to convert path(s) to utf-8, path(s) = {0}")]
    PathConversionError(String),
    #[error("Failed to read name of this binary, cause: {0:?}")]
    SelfReadError(std::io::Error),
    #[error("Failed to start command {0} {1:?}")]
    CommandStartError(String, std::io::Error),
    #[error("Failed to run command {0} stdout {1} stderr {2}")]
    CommandExecutionError(String, String, String),
    #[error("Failed to run command {0}")]
    CommandExitError(String),
    #[error("Failed to parse number from input {0}")]
    NumberParseError(String),
    #[error(transparent)]
    StringParseError(#[from] FromUtf8Error),
    #[error("Failed to read metadata at path {0:?}, cause: {1:?}")]
    ReadMetadataError(PathBuf, std::io::Error),
    #[error("Failed to write file at path {0:?}, cause: {1:?}")]
    FileWriteError(PathBuf, std::io::Error),
    #[error("Failed to read file at path {0:?}, cause: {1:?}")]
    FileReadError(PathBuf, std::io::Error),
    #[error("Failed to read file from {0:?}, to {1:?} cause: {2:?}")]
    FileCopyError(PathBuf, PathBuf, std::io::Error),
    #[error("Failed to read input from stdin")]
    StdinReadError,
}
