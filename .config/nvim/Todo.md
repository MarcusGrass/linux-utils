# Todo

## General

General necessary fixes

### Sneak

- [ ] Underscore searches doesn't work, cancels search, check settings

### Markdown rendering

- [x] Markdown code `like this` is not rendered properly (invisible), may be a catppuccing issue, was shipped `/usr/share/nvim/runtime/ftplugin/help.vim` [from source](https://github.com/neovim/neovim/blob/master/runtime/ftplugin/help.vim)
debugged by finding a file that didn't render properly and running `:verbose set conceallevel`.

## Fuzzy search sources

Probably some LSP integration, in the `Rust` case I need to know where Cargo stores the specific sources for a given project and fuzzy-search in there,
I would like to NvimTree the sources. 

Could probably be implemented with Telescope, I need to list the unique sources and versions (found in Cargo.lock), 
then find those local dependencies they should be in `~/.cargo.registry/src/index.crate.io-<hash>`. 
However, that hash is suspect, I could wildcard match it... 

Ideally I could open a separate nvimtree for the dependency, but it seems to be WIP: https://github.com/nvim-tree/nvim-tree.lua/issues/2255


## Diffview

- [x] open specific file with <C-ENTER> or similar, currently <C-w>gf


## Telescope

- [x] Find files not working at some depth
- [ ] treesitter on diff buffers on custom differ

## Lsp

- [x] Figure out how to go to inline type-hint definitions
- [ ] Tresitter on rendered hover-buffers


## Additions

### jq

- [x] Add jq formatting with vim.notify on errors formatting (added conform with jq)

