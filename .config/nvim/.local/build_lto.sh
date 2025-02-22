#!/bin/sh
cargo b -p main-config --profile lto && cp target/lto/libmain_config.so ./.rlib/lua/main_config.so

