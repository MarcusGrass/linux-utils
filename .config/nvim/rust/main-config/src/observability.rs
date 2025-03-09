use nvim_oxi::Dictionary;
use tracing_subscriber::fmt::MakeWriter;

pub fn setup() {
    tracing_subscriber::fmt()
        .with_ansi(false)
        .with_writer(MakeVimNotifyWriter)
        .init();
}

struct VimNotifyWriter;

struct MakeVimNotifyWriter;

impl<'a> MakeWriter<'a> for MakeVimNotifyWriter {
    type Writer = VimNotifyWriter;

    #[inline]
    fn make_writer(&'a self) -> Self::Writer {
        VimNotifyWriter
    }
}

impl std::io::Write for VimNotifyWriter {
    fn write(&mut self, buf: &[u8]) -> std::io::Result<usize> {
        let msg = String::from_utf8_lossy(buf);
        let _ = nvim_oxi::api::notify(
            &msg,
            nvim_oxi::api::types::LogLevel::Warn,
            &Dictionary::new(),
        );
        Ok(buf.len())
    }

    #[inline]
    fn flush(&mut self) -> std::io::Result<()> {
        let _ = nvim_oxi::api::notify(
            "flushed",
            nvim_oxi::api::types::LogLevel::Warn,
            &Dictionary::new(),
        );
        Ok(())
    }
}
