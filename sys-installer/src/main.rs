use crate::install::chroot_gentoo_finalize::chroot_gentoo_finalize;
use crate::install::chroot_gentoo_prep::chroot_gentoo_prep;
use crate::install::enter::enter;
use crate::install::prep_gentoo::prep_gentoo;
use crate::install::root_configure_system::root_configure_system;
use crate::install::user_configure_system::user_configure_system;
use crate::opt::Opt;
use structopt::StructOpt;

mod cfg;
mod error;
mod install;
mod native_interactions;
mod opt;
mod util;

#[tokio::main]
async fn main() -> error::Result<()> {
    let opts: Opt = Opt::from_args();
    match opts {
        Opt::Base(cfg_path) => prep_gentoo(&cfg_path).await?,
        Opt::Enter(cfg_path) => enter(&cfg_path).await?,
        Opt::ChrootPrep(cfg_path) => chroot_gentoo_prep(&cfg_path).await?,
        Opt::ChrootFinalize(cfg_path) => chroot_gentoo_finalize(&cfg_path).await?,
        Opt::CfgRoot(cfg_path) => root_configure_system(&cfg_path).await?,
        Opt::CfgUser(cfg_path) => user_configure_system(&cfg_path).await?,
    }
    Ok(())
}
