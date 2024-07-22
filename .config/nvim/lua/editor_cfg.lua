--- Cosmetic ---
-- Enables 24-bit RGB https://neovim.io/doc/user/options.html#'termguicolors'
vim.opt.termguicolors = true
-- Syntax highlighting needs to come after background and colors_name https://neovim.io/doc/user/options.html#'syntax'
vim.opt.syntax = "ON"

--- Spelling
vim.opt.spelllang = "en_us"
vim.opt.spell = true

--- Keys
vim.g.mapleader = " "

--- Editing
-- Matching pairs https://neovim.io/doc/user/options.html#'matchpairs'
table.insert(vim.opt.matchpairs, "<:>")

--- Quirks
-- Hide buffers whe abandoned, TextEdit might fail if hidden is not set.
vim.opt.hidden = true
-- Indicate fast terminal connection
vim.opt.ttyfast = true
-- Autoindent https://neovim.io/doc/user/options.html#'autoindent'
vim.opt.autoindent = true
-- Try to indent new lines https://neovim.io/doc/user/options.html#'smartindent'
vim.opt.smartindent = true

-- Share system clipboard https://neovim.io/doc/user/options.html#'clipboard'
vim.opt.clipboard = "unnamed,unnamedplus"

-- Mouse in normal mode https://neovim.io/doc/user/options.html#'mouse'
vim.opt.mouse = "n"

-- Scroll jump minimum line when cursor goes off screen https://neovim.io/doc/user/options.html#'scrolljump'
vim.opt.scrolljump = 10
-- Minimum number of lines to keep above the cursor https://neovim.io/doc/user/options.html#'scrolloff'
vim.opt.scrolloff = 10

-- Highlight search matches https://neovim.io/doc/user/options.html#'hlsearch'
vim.opt.hlsearch = true
-- Ignorecase in searches https://neovim.io/doc/user/options.html#'ignorecase'
vim.opt.ignorecase = true
-- Override ignorecase if search containser uppercase letters https://neovim.io/doc/user/options.html#'smartcase'
vim.opt.smartcase = true
-- Incremental searching, defaults to on but whatever https://neovim.io/doc/user/options.html#'incsearch'
vim.opt.incsearch = true

-- Use spaces when tabbing https://neovim.io/doc/user/options.html#'expandtab'
vim.opt.expandtab = true
-- Use 4 spaces for tabs https://neovim.io/doc/user/options.html#'expandtab'
vim.opt.shiftwidth = 4
-- When editing, this is the number of spaces, -1 refers to `shiftwidth`
vim.opt.softtabstop = -1
-- All these work together to make tabs spaces https://neovim.io/doc/user/options.html#'tabstop'
vim.opt.tabstop = 4

-- Show line numbers https://neovim.io/doc/user/options.html#'number'
vim.opt.number = true

-- Complete options https://neovim.io/doc/user/options.html#'completeopt'
vim.opt.completeopt = "menu,menuone,noinsert,noselect"
-- Fewer prompt from file messages
table.insert(vim.opt.shortmess, "c")

-- Update time, used for cursor hold (and write from swap to disk) https://neovim.io/doc/user/options.html#'updatetime'
-- (milliseconds)
vim.opt.updatetime = 300

-- Have a fixed column for the diagnostics to appear in
-- this removes the jitter when warnings/errors flow in
vim.opt.signcolumn = "yes:1"

--- Enable Lsp inlay hints, could be moved to pluginit, or set as a toggle
vim.lsp.inlay_hint.enable(true)
