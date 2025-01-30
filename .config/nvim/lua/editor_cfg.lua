--- Cosmetic ---
-- Enables 24-bit RGB https://neovim.io/doc/user/options.html#'termguicolors'
vim.opt.termguicolors = true

--- Spelling
vim.opt.spelllang = "en_us"
vim.opt.spell = true

--- Keys
vim.g.mapleader = " "

--- Keep undos persistent, and pick a directory to not save it next to the files being edited
--- https://neovim.io/doc/user/undo.html#undo-persistence
--- Vim seems to be able to create these by itself
local prefix = vim.env.XDG_CACHE_HOME or vim.fn.expand("~/.cache")
local undo_dir = { prefix .. "/nvim/.undo//" }
local backup_dir = { prefix .. "/nvim/.backup//" }
local directory = { prefix .. "/nvim/.swp//" }

vim.opt.undodir = undo_dir
vim.opt.backupdir = backup_dir
vim.opt.directory = directory
vim.opt.undofile = true
--- https://neovim.io/doc/user/options.html#'undolevels'
--- Default is 1000, set to 100_000, how many undos to save
vim.opt.undolevels = 100000
--- https://neovim.io/doc/user/options.html#'undoreload'
--- Default is 10_000, set to 100_000,
vim.opt.undoreload = 100000

--- Editing
-- Matching pairs https://neovim.io/doc/user/options.html#'matchpairs'
vim.opt.matchpairs:append("<:>")

--- Lines
--- I want line-breaks to be visible
vim.opt.listchars = {
    eol = "↵"
}
vim.opt.list = true
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
