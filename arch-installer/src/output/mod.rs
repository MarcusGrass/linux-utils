#[macro_export]
macro_rules! debug {
    ($($arg:tt)*) => {{
        eprintln!("[{}:L#{}] {}", file!(), line!(), format_args!($($arg)*));
    }}
}

#[macro_export]
macro_rules! info {
    ($($arg:tt)*) => {{
        eprintln!("[{}:L#{}] {}", file!(), line!(), format_args!($($arg)*));
    }}
}

#[macro_export]
macro_rules! warn {
    ($($arg:tt)*) => {{
        eprintln!("[{}:L#{}] {}", file!(), line!(), format_args!($($arg)*));
    }}
}

#[macro_export]
macro_rules! error {
    ($($arg:tt)*) => {{
        eprintln!("[{}:L#{}] {}", file!(), line!(), format_args!($($arg)*));
    }}
}
