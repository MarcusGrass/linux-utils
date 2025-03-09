# Todo

## Replacements

- [x] Use Snacks pickers over Telescope, remove Telescope completely.
- [x] Switch to neotree, needs to implement search-in-dir.

## QoL

Maybe not necessary, but still important fixes

### Rust specifics

- [ ] Custom picker for rust commands like `cargo fmt --all` which pops a window with the output
- [ ] See if rust-analyzer autocomplete on derives can be prevented from generating trailing `()`

### Cargo auto-complete on deps

- [x] The `cargo` plugin check dependency versions, but not (at least not as configured) available features, autocomplete on toml format etc.

## General

General necessary fixes

### Window picker

- [ ] Duplicate window in split, should be easy enough, probably already as a 
default command, but I want to pick where it's opened
- [x] Fix so that opens can target any window
- [ ] Bind lsp things like go-to-def which doesn't usually pop snacks so that they can be intercepted

### Snacks

#### Picker

Backspace doesn't work in input window insert mode, shift+backspace does however. could be some other part of my config that's busted.

### Sneak

- [ ] Underscore searches doesn't work, cancels search, check settings, should open a ticket

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
- [x] custom git log picker

## Fugitive

- [ ] Make a picker for standard commands like `fetch` `pull` `rebase` etc.
- [ ] Do something to make cherry-picking easier `git log --left-right --graph --cherry-pick --oneline HEAD..mg/cm-power-hostname-state`, maybe add a picker to show the commit diffs there

## Lsp

- [x] Figure out how to go to inline type-hint definitions
- [ ] Tresitter on rendered hover-buffers


## Additions

### jq

- [x] Add jq formatting with vim.notify on errors formatting (added conform with jq)

