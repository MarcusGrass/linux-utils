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

#[derive(clap::Parser, Debug)]
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
struct Mirror {
    uri: Uri,
    ping: Duration,
    location: String,
    repo: String,
}

fn set_up_client(args: &Args) -> Client<HttpsConnector<HttpConnector>> {
    let https = if args.https_only {
        if args.verbose {
            println!("[arch-rank-mirrors] Creating https only connector");
        }
        hyper_rustls::HttpsConnectorBuilder::new()
            .with_native_roots()
            .https_only()
            .enable_http1()
            .enable_http2()
            .build()
    } else {
        if args.verbose {
            println!("[arch-rank-mirrors] Creating http or https connector");
        }
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
    mirrors.extend(parse_mirror_list(arch, repos, sample, args)?);
    for repo in repos {
        let path = args.create_mirror_list_path(repo);
        mirrors.extend(parse_mirror_list(arch, repos, path, args)?);
    }
    Ok(mirrors)
}

fn parse_mirror_list(
    arch: &str,
    repos: &[String],
    path: PathBuf,
    args: &Args,
) -> Result<Vec<Mirror>> {
    if args.verbose {
        println!("[arch-rank-mirrors] Searching {path:?} for sample mirror list");
    }
    if let Ok(meta) = std::fs::metadata(&path) {
        if !meta.is_file() {
            return Ok(vec![]);
        }
    } else {
        return Ok(vec![]);
    }
    let raw_file = std::fs::read_to_string(&path)?;
    let mut mirrors = vec![];
    let mut cur_location: Option<String> = None;
    for line in raw_file.lines() {
        if line.is_empty() {
            continue;
            // Pretty overdone heuristic, but performance in this part doesn't matter at all
        } else if line.contains("Server") && line.contains('=') && line.contains("http") {
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
                            eprintln!("[WARN] Failed to parse line {line}: No location data found in above lines - skipping");
                        }
                    } else {
                        eprintln!(
                            "[WARN] Failed to parse line {line}: Failed to parse URI - skipping"
                        );
                    }
                } else {
                    eprintln!("[WARN] Failed to parse line {line}: Couldn't properly split on '='")
                }
            }
        } else if line.trim().starts_with("##") {
            let location = line.trim().replace("## ", "");
            cur_location = Some(location.trim().to_string());
        }
    }
    if args.verbose {
        println!(
            "[arch-rank-mirrors] Fount {} mirrors at {path:?}",
            mirrors.len()
        );
    }
    Ok(mirrors)
}

fn get_used_repos(args: &Args) -> Result<Vec<String>> {
    let repos = if args.repos.is_empty() {
        let raw_file = std::fs::read_to_string("/etc/pacman.conf")?;
        let mut on_repo: Option<String> = None;
        let mut repos = vec![];
        for line in raw_file.lines() {
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
    } else {
        args.repos.clone()
    };
    if args.verbose {
        println!("[arch-rank-mirror] Looking for repos {:?}", repos);
    }
    Ok(repos)
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
    if args.verbose {
        println!("[arch-rank-mirror] Using arch {arch}");
    }
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
    if args.verbose {
        println!("[arch-rank-mirror] Using {cpus} as num-concurrent requests, starting test");
    }
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

    if args.verbose {
        println!("[arch-rank-mirror] Finished mirror test");
    }
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
        println!("[arch-rank-mirror] Not creating backup for {pacman_conf:?}");
    } else {
        backup_if_exists(pacman_conf.clone(), args)?;
    }
    for (repo, mirrors) in mirrors.iter_mut() {
        mirrors.sort_by_key(|m| m.ping);
        if args.no_commit {
            if args.verbose {
                println!("[arch-rank-mirror] Dry run, not updating mirrors");
            }
        } else if args.min_mirrors.unwrap_or(5) <= mirrors.len() {
            if args.verbose {
                println!(
                    "[arch-rank-mirror] Writing new mirror list with {} mirrors for repo {repo}",
                    mirrors.len()
                );
            }
            let wrote_to_path = replace_with_backup(repo, mirrors, args)?;
            edit_pacman_conf(repo, &pacman_conf, wrote_to_path, args)?;
        } else if args.verbose {
            println!(
                "[arch-rank-mirror] Not writing mirror list, too few mirrors: {} for repo {repo}",
                mirrors.len()
            );
        }
    }
    Ok(())
}

fn backup_if_exists(path: PathBuf, args: &Args) -> Result<()> {
    let mut backup = path.clone().into_os_string();
    backup.push(".old");
    if args.verbose {
        println!("[arch-rank-mirror] Creating backup for {path:?} at {backup:?}");
    }
    if let Ok(meta) = std::fs::metadata(&path) {
        if meta.is_dir() {
            return Err(Error::FS(format!(
                "Supplied backup is a directory, not a file {path:?}"
            )));
        } else {
            std::fs::copy(path, backup)?;
        }
    } else if args.verbose {
        println!("[arch-rank-mirror] Nothing to back up at {path:?}");
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
    if args.verbose {
        println!("[arch-rank-mirror] Writing mirror list to {path:?}");
    }
    std::fs::write(&path, mirrors_to_file(repo, mirrors))?;
    Ok(())
}

fn mirrors_to_file(repo: &str, mirrors: &[Mirror]) -> String {
    let mut content = format!("## Generated mirrorlist by arch-mirror-rank\n##\n##{repo}\n");
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
    if args.verbose {
        println!("[arch-rank-mirror] Updating mirror list for repo {repo} in {pacman_conf:?}");
    }
    let content = std::fs::read_to_string(pacman_conf)?;
    let mut new_content = String::new();
    let mut on_repo = false;
    for line in content.lines() {
        if line.trim().starts_with(&format!("[{repo}]")) {
            on_repo = true;
            let _ = new_content.write_fmt(format_args!("{line}\n"));
        } else if on_repo {
            let _ = new_content.write_fmt(format_args!("Include = {}\n", mirror_path_str));
            on_repo = false;
        } else {
            let _ = new_content.write_fmt(format_args!("{line}\n"));
        }
    }
    if args.verbose {
        println!("[arch-rank-mirror] Writing modified {pacman_conf:?}");
    }
    std::fs::write(pacman_conf, new_content.as_bytes())?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use crate::{get_arch, get_used_repos};

    #[test]
    fn get_cur_arch() {
        eprintln!("{}", get_arch().unwrap());
    }

    #[test]
    fn used_repos() {
        eprintln!("{:?}", get_used_repos().unwrap());
    }
}
