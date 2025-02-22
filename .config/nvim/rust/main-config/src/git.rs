use nvim_oxi::Dictionary;

use crate::{Error, command::run_command};
const FORMAT_SEP: &str = "<|COMMIT-SEP-TOKEN|>";
#[expect(clippy::needless_pass_by_value)]
pub fn get_file_change_commits(file: String) -> Dictionary {
    match do_get_file_change_commits(&file) {
        Ok(o) => o,
        Err(e) => {
            tracing::error!("failed to run git diff: {e:#?}");
            Dictionary::new()
        }
    }
}

fn do_get_file_change_commits(file: &str) -> nvim_oxi::Result<Dictionary> {
    let mut cmd = std::process::Command::new("git");
    cmd.arg("--no-pager")
        .arg("log")
        .arg(format!(
            "--pretty=format:\"%H{FORMAT_SEP}%h{FORMAT_SEP}[%cs]{FORMAT_SEP}%an{FORMAT_SEP}%s\""
        ))
        .arg("--")
        .arg(file);
    let output = run_command(cmd)?;
    let mut slice = Dictionary::new();
    let mut ind = 1;
    for line in output.lines() {
        let mut split = line.trim_matches('"').split(FORMAT_SEP);
        let (Some(long_hash), Some(short_hash), Some(short_date), Some(author), Some(subject)) = (
            split.next(),
            split.next(),
            split.next(),
            split.next(),
            split.next(),
        ) else {
            return Err(Error::Unrecoverable(anyhow::anyhow!(
                "failed to run parse git log pretty output from line={line}"
            ))
            .into());
        };
        let mut entry = Dictionary::new();
        entry.insert("sha", long_hash);
        entry.insert("sha_short", short_hash);
        entry.insert("date", short_date);
        entry.insert("author", author);
        entry.insert("subject", subject);
        slice.insert(ind.to_string(), entry);
        ind += 1;
    }
    Ok(slice)
}
