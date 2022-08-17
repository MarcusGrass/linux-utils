#[macro_export]
#[cfg(feature = "debug")]
macro_rules! debug {
    ($($arg:tt)*) => {{
        eprintln!("[{}:L#{}] {}", file!(), line!(), format_args!($($arg)*));
    }}
}
#[macro_export]
#[cfg(not(feature = "debug"))]
macro_rules! debug {
    ($($arg:tt)*) => {{}};
}

#[macro_export]
#[cfg(feature = "debug")]
macro_rules! info {
    ($($arg:tt)*) => {{
        eprintln!("[{}:L#{}] {}", file!(), line!(), format_args!($($arg)*));
    }}
}
#[macro_export]
#[cfg(not(feature = "debug"))]
macro_rules! info {
    ($($arg:tt)*) => {{}};
}

#[macro_export]
#[cfg(feature = "debug")]
macro_rules! warn {
    ($($arg:tt)*) => {{
        eprintln!("[{}:L#{}] {}", file!(), line!(), format_args!($($arg)*));
    }}
}
#[macro_export]
#[cfg(not(feature = "debug"))]
macro_rules! warn {
    ($($arg:tt)*) => {{}};
}

#[macro_export]
#[cfg(feature = "debug")]
macro_rules! error {
    ($($arg:tt)*) => {{
        eprintln!("[{}:L#{}] {}", file!(), line!(), format_args!($($arg)*));
    }}
}
#[macro_export]
#[cfg(not(feature = "debug"))]
macro_rules! error {
    ($($arg:tt)*) => {{}};
}
