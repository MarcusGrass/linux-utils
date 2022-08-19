use clap::Parser;
use futures::stream::FuturesUnordered;
use futures::StreamExt;
use hyper::body::HttpBody;
use hyper::client::HttpConnector;
use hyper::{header, Body, Client, Uri};
use hyper_rustls::HttpsConnector;
use std::collections::hash_map::Entry;
use std::collections::HashMap;
use std::fmt::Write;
use std::path::PathBuf;
use std::time::{Duration, Instant};
use tokio::time::timeout;

const BAD_PING: Duration = Duration::from_secs(2000);
const DEFAULT_TIMEOUT: u64 = 2000;

#[derive(Debug, thiserror::Error)]
pub enum Error {
    #[error(transparent)]
    Io(#[from] std::io::Error),
    #[error("Http error: {0}")]
    Http(String),
    #[error("Joining threads: {0}")]
    Join(String),
    #[error("Process: {0}")]
    Process(String),
    #[error("Parse: {0}")]
    Parse(String),
    #[error("Filesystem: {0}")]
    FS(String),
}

pub type Result<T> = std::result::Result<T, Error>;

macro_rules! verbose_print {
    ($args: expr, $($arg:tt)*) => {{
        if $args.verbose {
            println!("[arch-mirror-rank] {}", format_args!($($arg)*));
        }
    }}
}

#[derive(clap::Parser, Debug)]
#[cfg_attr(test, derive(Default))]
#[clap(author, version)]
struct Args {
    /// Architecture for which to search mirrors, if empty, will try to use `uname -m` to acquire
    #[clap(short, long)]
    arch: Option<String>,

    /// Whether to only use https mirrors
    #[clap(short, long)]
    https_only: bool,

    /// If true, will not create a backup of overwritten mirror list,
    /// if false (default), will replace old mirrorlist with `<name>.old`
    #[clap(long)]
    no_backups: bool,

    /// If true, will not make any changes to `pacman_conf`,
    /// if false (default), will write new mirrors into `pacman_conf`
    #[clap(long)]
    no_commit: bool,

    /// Max concurrent outstanding requests, depending on the user's machine and internet connection
    /// a higher number might skew results, but it will be faster.
    /// If empty will use a heuristic based on number of cpus
    #[clap(long)]
    max_concurrent: Option<usize>,

    /// Minimum amount of acceptable mirror to commit a new mirror list, defaults to `5`
    #[clap(long)]
    min_mirrors: Option<usize>,

    /// Path where mirror lists should be written, defaults to `/etc/pacman.d/`
    #[clap(long)]
    mirror_list_dir: Option<PathBuf>,

    /// Path to pacman_conf will default to `/etc/pacman.conf`
    #[clap(short, long)]
    pacman_conf: Option<PathBuf>,

    /// Which repos to search, if empty, will check `/etc/pacman.conf` for selected mirrors
    #[clap(short, long)]
    repos: Vec<String>,

    /// Path to sample mirror list, if not provided will check `/etc/pacman.d/mirrorlist`
    /// and eventual mirror lists written by this utility in `mirror_list_dir`
    #[clap(short, long)]
    sample_mirror_list: Option<PathBuf>,

    /// Max tolerated timeout in milliseconds used when checking mirrors,
    /// defaults to `1000`
    #[clap(short, long)]
    timeout: Option<u64>,

    /// Verbose output for debuging
    #[clap(short, long)]
    verbose: bool,
}

impl Args {
    fn create_mirror_list_path(&self, repo: &str) -> PathBuf {
        if let Some(mirror_list_dir) = &self.mirror_list_dir {
            mirror_list_dir.join(format!("{repo}-mirrorlist"))
        } else {
            PathBuf::from(format!("/etc/pacman.d/{repo}-mirrorlist"))
        }
    }
}

#[tokio::main]
async fn main() -> Result<()> {
    let args = Args::parse();
    let client = set_up_client(&args);
    let arch = get_arch(&args)?;
    let repos = get_used_repos(&args)?;
    let mirrors = parse_mirror_lists(&arch, &repos, &args)?;
    let mirrors_by_repo = test_mirrors(client, mirrors, &args).await?;
    rank_and_dump_mirrors(mirrors_by_repo, &args)?;
    Ok(())
}

#[derive(Debug, Clone)]
#[cfg_attr(test, derive(Eq, PartialEq))]
struct Mirror {
    uri: Uri,
    ping: Duration,
    location: String,
    repo: String,
}

fn set_up_client(args: &Args) -> Client<HttpsConnector<HttpConnector>> {
    let https = if args.https_only {
        verbose_print!(args, "Creating https only connector");
        hyper_rustls::HttpsConnectorBuilder::new()
            .with_native_roots()
            .https_only()
            .enable_http1()
            .enable_http2()
            .build()
    } else {
        verbose_print!(args, "Creating http or https connector");
        hyper_rustls::HttpsConnectorBuilder::new()
            .with_native_roots()
            .https_or_http()
            .enable_http1()
            .enable_http2()
            .build()
    };
    hyper::Client::builder().build::<_, Body>(https)
}

fn parse_mirror_lists(arch: &str, repos: &[String], args: &Args) -> Result<Vec<Mirror>> {
    let mut mirrors = vec![];
    let sample = args
        .sample_mirror_list
        .clone()
        .unwrap_or_else(|| PathBuf::from("/etc/pacman.d/mirrorlist"));
    if let Some(sample) = read_mirror_list(sample, args)? {
        mirrors.extend(parse_mirror_list(arch, repos, sample, args));
    }
    for repo in repos {
        let path = args.create_mirror_list_path(repo);
        if let Some(content) = read_mirror_list(path, args)? {
            mirrors.extend(parse_mirror_list(arch, repos, content, args));
        }
    }
    Ok(mirrors)
}

fn read_mirror_list(path: PathBuf, args: &Args) -> Result<Option<String>> {
    verbose_print!(args, "Searching {path:?} for sample mirror list");
    if let Ok(meta) = std::fs::metadata(&path) {
        if !meta.is_file() {
            return Ok(None);
        }
    } else {
        return Ok(None);
    }
    Ok(Some(std::fs::read_to_string(&path)?))
}

fn parse_mirror_list(arch: &str, repos: &[String], raw_file: String, args: &Args) -> Vec<Mirror> {
    let mut mirrors = vec![];
    let mut cur_location: Option<String> = None;
    for line in raw_file.lines() {
        if line.is_empty() {
            continue;
            // Pretty overdone heuristic, but performance in this part doesn't matter at all
        } else if line.contains("Server") && line.contains('=') && line.contains("http") {
            if args.https_only && !line.contains("https") {
                continue;
            }
            for repo in repos {
                // looks something like http://<blablabla>/$repo/os/$arch
                if let Some(template_url) = line.split('=').nth(1) {
                    if let Ok(uri) = template_url
                        .trim()
                        .replace("$repo", repo)
                        .replace("$arch", arch)
                        .parse::<Uri>()
                    {
                        if let Some(location) = cur_location.clone() {
                            mirrors.push(Mirror {
                                uri,
                                ping: BAD_PING,
                                location,
                                repo: repo.clone(),
                            })
                        } else {
                            verbose_print!(args, "Failed to parse line {line}: No location data found in above lines - skipping");
                        }
                    } else {
                        verbose_print!(
                            args,
                            "Failed to parse line {line}: Failed to parse URI - skipping"
                        );
                    }
                } else {
                    verbose_print!(
                        args,
                        "Failed to parse line {line}: Couldn't properly split on '='"
                    )
                }
            }
        } else if line.trim().starts_with("##") {
            let location = line.trim().replace("## ", "");
            cur_location = Some(location.trim().to_string());
        }
    }
    verbose_print!(args, "Found {} mirrors", mirrors.len());
    mirrors
}

fn get_used_repos(args: &Args) -> Result<Vec<String>> {
    let repos = if args.repos.is_empty() {
        let raw_file = std::fs::read_to_string("/etc/pacman.conf")?;
        parse_used_repos(raw_file)
    } else {
        args.repos.clone()
    };
    verbose_print!(args, "Looking for repos {:?}", repos);
    Ok(repos)
}

fn parse_used_repos(content: String) -> Vec<String> {
    let mut on_repo: Option<String> = None;
    let mut repos = vec![];
    for line in content.lines() {
        if line.trim().starts_with('[') && line.trim().ends_with(']') {
            let repo_name = line.trim().replace('[', "").replace(']', "");
            on_repo = Some(repo_name);
        } else if let Some(repo_name) = on_repo.clone() {
            if line.starts_with("Include") {
                repos.push(repo_name);
                on_repo.take();
            }
        }
    }
    repos
}

fn get_arch(args: &Args) -> Result<String> {
    let arch = if let Some(arch) = args.arch.clone() {
        arch
    } else {
        let vec = std::process::Command::new("uname")
            .arg("-m")
            .output()
            .map_err(|e| Error::Process(format!("Failed to check `uname -m` {e}")))?
            .stdout;
        String::from_utf8(vec)
            .map_err(|e| {
                Error::Parse(format!(
                    "Failed to parse output of `uname -m` as a utf-8 string {e}"
                ))
            })?
            .trim()
            .to_string()
    };
    verbose_print!(args, "Using arch {arch}");
    Ok(arch)
}

async fn test_mirrors(
    client: Client<HttpsConnector<HttpConnector>>,
    mirrors: Vec<Mirror>,
    args: &Args,
) -> Result<HashMap<String, Vec<Mirror>>> {
    let mut unordered = FuturesUnordered::new();
    let mut below_deadline_mirrors = HashMap::new();
    let cpus = args.max_concurrent.unwrap_or_else(|| num_cpus::get() * 4);
    verbose_print!(
        args,
        "Using {cpus} as num-concurrent requests, starting test"
    );
    for mirror in mirrors {
        if unordered.len() > cpus {
            let res: std::result::Result<Mirror, _> = unordered.next().await.unwrap();
            let mirror = res.map_err(|e| Error::Join(format!("Outstanding request {e}")))?;
            if mirror.ping != BAD_PING {
                match below_deadline_mirrors.entry(mirror.repo.clone()) {
                    Entry::Vacant(v) => {
                        v.insert(vec![mirror]);
                    }
                    Entry::Occupied(mut o) => {
                        o.get_mut().push(mirror);
                    }
                }
            }
        } else {
            unordered.push(tokio::spawn(time_mirror(
                client.clone(),
                mirror,
                args.timeout.unwrap_or(DEFAULT_TIMEOUT),
            )));
        }
    }
    while let Some(next) = unordered.next().await {
        let mirror = next.map_err(|e| Error::Join(format!("Outstanding request {e}")))?;
        if mirror.ping != BAD_PING {
            match below_deadline_mirrors.entry(mirror.repo.clone()) {
                Entry::Vacant(v) => {
                    v.insert(vec![mirror]);
                }
                Entry::Occupied(mut o) => {
                    o.get_mut().push(mirror);
                }
            }
        }
    }

    verbose_print!(args, "Finished mirror test");
    Ok(below_deadline_mirrors)
}

async fn time_mirror(
    client: Client<HttpsConnector<HttpConnector>>,
    mirror: Mirror,
    deadline: u64,
) -> Mirror {
    let cloned = mirror.clone();
    match timeout(
        Duration::from_millis(deadline),
        run_request_on_mirror(client, mirror),
    )
    .await
    {
        Ok(m) => m,
        Err(_) => cloned,
    }
}

async fn run_request_on_mirror(
    client: Client<HttpsConnector<HttpConnector>>,
    mut mirror: Mirror,
) -> Mirror {
    let start = Instant::now();
    let res = client.get(mirror.uri.clone()).await.map_err(|e| {
        Error::Http(format!(
            "Failed to send get request to {} {}",
            mirror.uri, e
        ))
    });
    if let Ok(mut res) = res {
        if res.status().is_success() {
            while res.body_mut().data().await.is_some() {}
            mirror.ping = start.elapsed();
        } else if res.status().is_redirection() {
            let redirect = res.headers().get(header::LOCATION);
            if let Some(redirect) = redirect {
                if let Ok(str) = redirect.to_str() {
                    if let Ok(uri) = str.parse::<Uri>() {
                        let res = client.get(uri.clone()).await.map_err(|e| {
                            Error::Http(format!("Failed to send get request to {} {}", uri, e))
                        });
                        if let Ok(mut res) = res {
                            if res.status().is_success() {
                                while res.body_mut().data().await.is_some() {}
                                mirror.ping = start.elapsed();
                            }
                        }
                    }
                }
            }
        }
    }
    mirror
}

fn rank_and_dump_mirrors(mut mirrors: HashMap<String, Vec<Mirror>>, args: &Args) -> Result<()> {
    let pacman_conf = args
        .pacman_conf
        .clone()
        .unwrap_or_else(|| PathBuf::from("/etc/pacman.conf"));
    if args.no_backups {
        verbose_print!(args, "Not creating backup for {pacman_conf:?}");
    } else {
        backup_if_exists(pacman_conf.clone(), args)?;
    }
    for (repo, mirrors) in mirrors.iter_mut() {
        mirrors.sort_by_key(|m| m.ping);
        if args.no_commit {
            verbose_print!(args, "Dry run, not updating mirrors");
        } else if args.min_mirrors.unwrap_or(5) <= mirrors.len() {
            verbose_print!(
                args,
                "Writing new mirror list with {} mirrors for repo {repo}",
                mirrors.len()
            );
            let wrote_to_path = replace_with_backup(repo, mirrors, args)?;
            edit_pacman_conf(repo, &pacman_conf, wrote_to_path, args)?;
        } else if args.verbose {
            // Double bool check here but whatever
            verbose_print!(
                args,
                "Not writing mirror list, too few mirrors: {} for repo {repo}",
                mirrors.len()
            );
        }
    }
    Ok(())
}

fn backup_if_exists(path: PathBuf, args: &Args) -> Result<()> {
    let mut backup = path.clone().into_os_string();
    backup.push(".old");
    verbose_print!(args, "Creating backup for {path:?} at {backup:?}");
    if let Ok(meta) = std::fs::metadata(&path) {
        if meta.is_dir() {
            return Err(Error::FS(format!(
                "Supplied backup is a directory, not a file {path:?}"
            )));
        } else {
            std::fs::copy(path, backup)?;
        }
    } else if args.verbose {
        verbose_print!(args, "Nothing to back up at {path:?}");
    }
    Ok(())
}

fn replace_with_backup(repo: &str, mirrors: &[Mirror], args: &Args) -> Result<PathBuf> {
    let path = args.create_mirror_list_path(repo);
    if let Ok(meta) = std::fs::metadata(&path) {
        if meta.is_dir() {
            return Err(Error::FS(format!(
                "Failed to write new mirrorlist path {path:?} exists an is a directory"
            )));
        } else {
            do_write_list(repo, mirrors, path.clone(), args)?;
        }
    } else {
        do_write_list(repo, mirrors, path.clone(), args)?;
    }
    Ok(path)
}

fn do_write_list(repo: &str, mirrors: &[Mirror], path: PathBuf, args: &Args) -> Result<()> {
    if !args.no_backups {
        backup_if_exists(path.clone(), args)?;
    }
    verbose_print!(args, "Writing mirror list to {path:?}");
    std::fs::write(&path, mirrors_to_file(repo, mirrors))?;
    Ok(())
}

fn mirrors_to_file(repo: &str, mirrors: &[Mirror]) -> String {
    let mut content = format!("## Generated mirrorlist by arch-mirror-rank\n##\n## {repo}\n");
    for mirror in mirrors {
        // Infallible barring some OOM
        let _ = content.write_fmt(format_args!(
            "## {}\nServer = {}\n",
            mirror.location, mirror.uri
        ));
    }
    content
}

fn edit_pacman_conf(
    repo: &str,
    pacman_conf: &PathBuf,
    mirror_list_path: PathBuf,
    args: &Args,
) -> Result<()> {
    let mirror_path_str = mirror_list_path.to_str().ok_or_else(|| {
        Error::Parse(format!(
            "Failed to convert mirror list path {:?} to utf8-str",
            mirror_list_path
        ))
    })?;
    verbose_print!(
        args,
        "Updating mirror list for repo {repo} in {pacman_conf:?}"
    );
    let content = std::fs::read_to_string(pacman_conf)?;
    let new_content = change_pacman_conf(repo, content, mirror_path_str);
    verbose_print!(args, "Writing modified {pacman_conf:?}");
    std::fs::write(pacman_conf, new_content.as_bytes())?;
    Ok(())
}

fn change_pacman_conf(repo: &str, content: String, mirror_path: &str) -> String {
    let mut new_content = String::new();
    let mut on_repo = false;
    for line in content.lines() {
        if line.trim().starts_with(&format!("[{repo}]")) {
            on_repo = true;
            let _ = new_content.write_fmt(format_args!("{line}\n"));
        } else if on_repo {
            let _ = new_content.write_fmt(format_args!("Include = {}\n", mirror_path));
            on_repo = false;
        } else {
            let _ = new_content.write_fmt(format_args!("{line}\n"));
        }
    }
    new_content
}

#[cfg(test)]
mod tests {
    use crate::{
        change_pacman_conf, get_arch, get_used_repos, mirrors_to_file, parse_mirror_list,
        parse_used_repos, Args, Mirror, BAD_PING,
    };
    use hyper::Uri;
    use std::path::PathBuf;

    #[test]
    #[cfg(target_arch = "x86_64")]
    fn get_cur_arch() {
        let mut dummy = Args::default();
        assert_eq!("x86_64", &get_arch(&dummy).unwrap());
        dummy.arch = Some("arm64".to_string());
        assert_eq!("arm64", &get_arch(&dummy).unwrap());
    }

    #[test]
    fn get_repos() {
        let expect = vec!["one".to_string(), "two".to_string()];
        let dummy = Args {
            repos: expect.clone(),
            ..Args::default()
        };
        let repos = get_used_repos(&dummy).unwrap();
        assert_eq!(expect, repos);
        let repos = parse_used_repos(SAMPLE_PACMAN_CONF.to_string());
        assert_eq!(
            vec![
                "core".to_string(),
                "extra".to_string(),
                "community".to_string(),
                "multilib".to_string()
            ],
            repos
        );
    }

    #[test]
    fn create_mirror_list_paths() {
        let mut dummy = Args::default();
        let mirror_list_path = dummy.create_mirror_list_path("repo");
        assert_eq!(
            "/etc/pacman.d/repo-mirrorlist",
            mirror_list_path.to_str().unwrap()
        );
        dummy.mirror_list_dir = Some(PathBuf::from("/home/user5/mirrors"));
        assert_eq!(
            "/home/user5/mirrors/repo-mirrorlist",
            dummy.create_mirror_list_path("repo").to_str().unwrap()
        );
    }

    #[test]
    fn parse_mirror() {
        let sample = "\
##
## Arch Linux repository mirrorlist
## Generated on 2022-07-24
##

## Worldwide
Server = https://geo.mirror.pkgbuild.com/$repo/os/$arch
Server = http://mirror.rackspace.com/archlinux/$repo/os/$arch
Server = https://mirror.rackspace.com/archlinux/$repo/os/$arch

## Australia
Server = https://mirror.aarnet.edu.au/pub/archlinux/$repo/os/$arch
Server = http://archlinux.mirror.digitalpacific.com.au/$repo/os/$arch
Server = https://archlinux.mirror.digitalpacific.com.au/$repo/os/$arch
        ";
        let mut dummy = Args::default();
        let mirrors = parse_mirror_list(
            "x86_64",
            &["community".to_string()],
            sample.to_string(),
            &dummy,
        );
        assert_eq!(6, mirrors.len());
        let expect_first = Mirror {
            uri: Uri::from_static("https://geo.mirror.pkgbuild.com/community/os/x86_64"),
            ping: BAD_PING,
            location: "Worldwide".to_string(),
            repo: "community".to_string(),
        };
        let expect_last = Mirror {
            uri: Uri::from_static(
                "https://archlinux.mirror.digitalpacific.com.au/community/os/x86_64",
            ),
            ping: BAD_PING,
            location: "Australia".to_string(),
            repo: "community".to_string(),
        };
        assert_eq!(expect_first, mirrors[0]);
        assert_eq!(expect_last, mirrors[5]);
        dummy.https_only = true;
        let mirrors = parse_mirror_list(
            "x86_64",
            &["community".to_string()],
            sample.to_string(),
            &dummy,
        );
        assert_eq!(4, mirrors.len());
    }

    #[test]
    fn test_change_pacman_conf() {
        let small_sample = "\
[core]
Include = /etc/pacman.d/mirrorlist

[extra]
Include = /etc/pacman.d/mirrorlist

#[community-testing]
#Include = /etc/pacman.d/mirrorlist

[community]
Include = /etc/pacman.d/mirrorlist

# If you want to run 32 bit applications on your x86_64 system,
# enable the multilib repositories as required here.

#[multilib-testing]
#Include = /etc/pacman.d/mirrorlist

[multilib]
Include = /etc/pacman.d/mirrorlist
";
        let core_path = "/home/user1/mirrors/core-mirrorlist";
        let changed = change_pacman_conf("core", small_sample.to_string(), core_path);
        let extra_path = "/home/user1/mirrors/extra-mirrorlist";
        let changed = change_pacman_conf("extra", changed, extra_path);
        let community_path = "/home/user1/mirrors/community-mirrorlist";
        let changed = change_pacman_conf("community", changed, community_path);
        let multilib_path = "/home/user1/mirrors/multilib-mirrorlist";
        let changed = change_pacman_conf("multilib", changed, multilib_path);
        assert_eq!(
            format!(
                "\
[core]
Include = {core_path}

[extra]
Include = {extra_path}

#[community-testing]
#Include = /etc/pacman.d/mirrorlist

[community]
Include = {community_path}

# If you want to run 32 bit applications on your x86_64 system,
# enable the multilib repositories as required here.

#[multilib-testing]
#Include = /etc/pacman.d/mirrorlist

[multilib]
Include = {multilib_path}
"
            ),
            changed
        );
    }

    #[test]
    fn test_mirrors_to_file() {
        let mirror1_uri = "https://archlinux.mirror.digitalpacific.com.au/community/os/x86_64";
        let mirror1_location = "Worldwide";
        let mirror1_repo = "community";
        let mirror_1 = Mirror {
            uri: Uri::from_static(mirror1_uri),
            ping: BAD_PING,
            location: mirror1_location.to_string(),
            repo: mirror1_repo.to_string(),
        };
        let mirror2_uri = "https://geo.mirror.pkgbuild.com/community/os/x86_64";
        let mirror2_location = "Spain";
        let mirror2_repo = "community";
        let mirror_2 = Mirror {
            uri: Uri::from_static(mirror2_uri),
            ping: BAD_PING,
            location: mirror2_location.to_string(),
            repo: mirror2_repo.to_string(),
        };
        let as_file = mirrors_to_file("community", &[mirror_1, mirror_2]);
        let expect = "\
## Generated mirrorlist by arch-mirror-rank
##
## community
## Worldwide
Server = https://archlinux.mirror.digitalpacific.com.au/community/os/x86_64
## Spain
Server = https://geo.mirror.pkgbuild.com/community/os/x86_64
";
        assert_eq!(expect.to_string(), as_file);
    }

    const SAMPLE_PACMAN_CONF: &str = "
#
# /etc/pacman.conf
#
# See the pacman.conf(5) manpage for option and repository directives

#
# GENERAL OPTIONS
#
[options]
# The following paths are commented out with their default values listed.
# If you wish to use different paths, uncomment and update the paths.
#RootDir     = /
#DBPath      = /var/lib/pacman/
#CacheDir    = /var/cache/pacman/pkg/
#LogFile     = /var/log/pacman.log
#GPGDir      = /etc/pacman.d/gnupg/
#HookDir     = /etc/pacman.d/hooks/
HoldPkg     = pacman glibc
#XferCommand = /usr/bin/curl -L -C - -f -o %o %u
#XferCommand = /usr/bin/wget --passive-ftp -c -O %o %u
#CleanMethod = KeepInstalled
Architecture = auto

# Pacman won't upgrade packages listed in IgnorePkg and members of IgnoreGroup
#IgnorePkg   =
#IgnoreGroup =

#NoUpgrade   =
#NoExtract   =

# Misc options
#UseSyslog
#Color
#NoProgressBar
CheckSpace
#VerbosePkgLists
ParallelDownloads = 25

# By default, pacman accepts packages signed by keys that its local keyring
# trusts (see pacman-key and its man page), as well as unsigned packages.
SigLevel    = Required DatabaseOptional
LocalFileSigLevel = Optional
#RemoteFileSigLevel = Required

# NOTE: You must run `pacman-key --init` before first using pacman; the local
# keyring can then be populated with the keys of all official Arch Linux
# packagers with `pacman-key --populate archlinux`.

#
# REPOSITORIES
#   - can be defined here or included from another file
#   - pacman will search repositories in the order defined here
#   - local/custom mirrors can be added here or in separate files
#   - repositories listed first will take precedence when packages
#     have identical names, regardless of version number
#   - URLs will have $repo replaced by the name of the current repo
#   - URLs will have $arch replaced by the name of the architecture
#
# Repository entries are of the format:
#       [repo-name]
#       Server = ServerName
#       Include = IncludePath
#
# The header [repo-name] is crucial - it must be present and
# uncommented to enable the repo.
#

# The testing repositories are disabled by default. To enable, uncomment the
# repo name header and Include lines. You can add preferred servers immediately
# after the header, and they will be used before the default mirrors.

#[testing]
#Include = /etc/pacman.d/mirrorlist

[core]
Include = /etc/pacman.d/mirrorlist

[extra]
Include = /etc/pacman.d/mirrorlist

#[community-testing]
#Include = /etc/pacman.d/mirrorlist

[community]
Include = /etc/pacman.d/mirrorlist

# If you want to run 32 bit applications on your x86_64 system,
# enable the multilib repositories as required here.

#[multilib-testing]
#Include = /etc/pacman.d/mirrorlist

[multilib]
Include = /etc/pacman.d/mirrorlist

# An example of a custom package repository.  See the pacman manpage for
# tips on creating your own repositories.
#[custom]
#SigLevel = Optional TrustAll
#Server = file:///home/custompkgs
";
}
