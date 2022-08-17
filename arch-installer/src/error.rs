pub type Result<T> = std::result::Result<T, Error>;

#[derive(Debug, thiserror::Error)]
pub enum Error {
    #[error("Failed to run crypt operation: {0}")]
    CryptError(String),
    #[error("Failed to parse devices: {0}")]
    ParseDevices(String),
    #[error("Failed to mount: {0}")]
    Mount(String),
    #[error("Filesystem error: {0}")]
    Fs(String),
    #[error("Process error: {0}")]
    Process(String),
}
