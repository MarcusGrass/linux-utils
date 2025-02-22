use std::process::Command;

pub type Result<T> = core::result::Result<T, Error>;
#[derive(Debug, thiserror::Error)]
pub enum Error {
    #[error("failed to run command = '{1:?}': {0:#?}")]
    Command(#[source] std::io::Error, Command),
    #[error("failed to run command = '{1:?}' got exit code {0}, stderr = {2}")]
    CommandStatus(std::process::ExitStatus, Command, String),
    #[error(transparent)]
    NvimOxi(#[from] nvim_oxi::Error),
    #[error(transparent)]
    NvimOxiApi(#[from] nvim_oxi::api::Error),
    #[error(transparent)]
    Unrecoverable(#[from] anyhow::Error),
}

impl From<Error> for nvim_oxi::Error {
    fn from(value: Error) -> Self {
        match value {
            Error::NvimOxiApi(error) => nvim_oxi::Error::Api(error),
            e => any_err_to_oxi(&e),
        }
    }
}

fn any_err_to_oxi(e: &dyn std::error::Error) -> nvim_oxi::Error {
    nvim_oxi::Error::Api(nvim_oxi::api::Error::Other(format!("{e:#?}")))
}
