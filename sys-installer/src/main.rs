use crate::install::chroot_gentoo_finalize::chroot_gentoo_finalize;
use crate::install::chroot_gentoo_prep::chroot_gentoo_prep;
use crate::install::prep_gentoo::prep_gentoo;
use crate::install::root_configure_system::root_configure_system;
use crate::install::user_configure_system::user_configure_system;
use crate::opt::Opt;
use structopt::StructOpt;

mod error;
mod install;
mod native_interactions;
mod opt;
mod util;

#[tokio::main]
async fn main() -> error::Result<()> {
    let opts: Opt = Opt::from_args();
    match opts {
        Opt::Base(mo) => prep_gentoo(&mo).await?,
        Opt::ChrootPrep => chroot_gentoo_prep().await?,
        Opt::ChrootFinalize => chroot_gentoo_finalize().await?,
        Opt::CfgRoot => root_configure_system().await?,
        Opt::CfgUser => user_configure_system().await?,
    }
    Ok(())
}
