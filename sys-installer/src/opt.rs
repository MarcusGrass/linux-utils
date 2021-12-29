use structopt::StructOpt;

#[derive(Debug, StructOpt)]
pub(crate) enum Opt {
    Enter(CfgPath),
    Base(CfgPath),
    ChrootPrep(CfgPath),
    ChrootFinalize(CfgPath),
    CfgRoot(CfgPath),
    CfgUser(CfgPath),
}

#[derive(Debug, StructOpt)]
pub(crate) struct CfgPath {
    #[structopt(short, long)]
    pub(crate) cfg: String,
}
