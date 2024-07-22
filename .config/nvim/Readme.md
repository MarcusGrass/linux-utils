# Guide for not breaking the CFG
## On update deps
Check that cfg works and save a snap
## On changing plugin cfg
Make sure that the snap with compatible cfg is saved
## On install 
Symlink the files from this directory to `~/.config/nvim` to make risk of local edits not being synced lower. 

# Lsp setup

## Rustaceanvim

Add rust-analyzer to the rust toolchain: 
```
rustup component add rust-analyzer
```

## luals

Install from [source](https://github.com/LuaLS/lua-language-server)

1. Clone
2. `./make.sh`
3. Make proxy bash file on path `exec "<path>" "$@"`


## pylsp

Can currently be found in gentoo repos at [dev-python/python-lsp-server](https://packages.gentoo.org/packages/dev-python/python-lsp-server), merge it, then 
it's good to go.

## gopls

Can currently be intalled through the go binary 
`go install golang.org/x/tools/gopls@latest` just make sure that 
the path is correct.

## Ccls

Can currently be found in gentoo repos at 
[dev-util/ccls](https://packages.gentoo.org/packages/dev-util/ccls), just merge.
