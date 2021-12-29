use futures::Future;
use indicatif::{ProgressBar, ProgressStyle};

pub fn default_bar(len: u64) -> ProgressBar {
    let pb = ProgressBar::new(len);
    let style = ProgressStyle::default_bar()
        .template("[{elapsed_precise}] {prefix} [{bar:60}] {pos:>3}/{len:3} {msg}")
        .progress_chars("=> ");
    pb.set_style(style);
    pb
}

pub async fn show_message_then_increment<F, O>(msg: String, future: F, pb: &ProgressBar) -> O
where
    F: Future<Output = O>,
{
    pb.set_message(msg);
    then_increment(future, pb).await
}

async fn then_increment<F, O>(future: F, pb: &ProgressBar) -> O
where
    F: Future<Output = O>,
{
    let res = future.await;
    pb.inc(1);
    res
}
