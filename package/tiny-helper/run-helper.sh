#!/bin/sh
RUSTFLAGS='-C panic=abort -C link-arg=-nostartfiles -C target-cpu=native -C target-feature=+crt-static -C relocation-model=static -C link-arg=-fuse-ld=mold' cargo r -r -- $@
