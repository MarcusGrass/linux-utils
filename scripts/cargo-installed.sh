#/bin/sh
set -ex
cargo install \
    bindgen-cli \
    flamegraph \
    cargo-deny \
    cargo-expand \
    cargo-fuzz \
    cargo-machete \
    cargo-tarpaulin \
    cross

