#!/bin/bash
set -e
cargo build --release --target x86_64-unknown-linux-musl
sudo mount /dev/sdb1 /media/
sudo cp target/x86_64-unknown-linux-musl/release/sys-installer /media/
sudo umount /media/
