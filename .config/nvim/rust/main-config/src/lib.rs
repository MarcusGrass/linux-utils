use nvim_oxi::{Array, Dictionary, Function, Object, api::Buffer};
mod error;
pub use error::{Error, Result};
mod command;
mod git;
mod observability;

#[nvim_oxi::plugin]
fn main_config() -> Dictionary {
    observability::setup();
    Dictionary::from_iter([
        (
            "buffer",
            Dictionary::from_iter([(
                "load_to_hidden",
                Object::from(Function::<String, nvim_oxi::Result<Buffer>>::from_fn(
                    load_to_hidden,
                )),
            )]),
        ),
        (
            "git",
            Dictionary::from_iter([(
                "get_file_change_commits",
                Object::from(Function::<String, Array>::from_fn(
                    git::get_file_change_commits,
                )),
            )]),
        ),
    ])
}

fn load_to_hidden(path: String) -> nvim_oxi::Result<Buffer> {
    let bufnr: Buffer = nvim_oxi::api::call_function("bufadd", (path,))?;
    Ok(bufnr)
}
