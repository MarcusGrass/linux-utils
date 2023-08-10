use crate::diff::DiffCommand;
use tiny_cli::arg_parse;

arg_parse!(
    #[name("Tiny helper")]
    #[description("Tiny helper to keep linux config up to date")]
    #[derive(Debug)]
    pub struct HelperOpts {
        #[subcommand("diff")]
        pub diff: Option<DiffCommand>,
    }
);
