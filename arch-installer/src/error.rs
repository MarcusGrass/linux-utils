pub type Result<T> = std::result::Result<T, Error>;

#[derive(Debug, thiserror::Error)]
pub enum Error {
    #[error("Failed to parse: {0}")]
    Parse(String),
    #[error("Filesystem error: {0}")]
    Fs(String),
    #[error("Process error: {0}")]
    Process(String),
}
