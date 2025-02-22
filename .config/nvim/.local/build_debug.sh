#!/bin/sh
cargo b -p main-config && cp target/debug/libmain_config.so ./.rlib/lua/main_config.so

