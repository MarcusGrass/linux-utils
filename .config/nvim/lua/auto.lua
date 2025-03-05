-- Open diagnostic on cursor hold
vim.api.nvim_create_autocmd(
    "CursorHold",
    { pattern = "*", command = "lua vim.diagnostic.open_float(nil, { focusable = false })" }
)

vim.api.nvim_create_autocmd(
    "TermClose",
    { pattern = "*", command = "if !v:event.status | exe 'bdelete! '..expand('<abuf>') | endif" }
)
-- We opened a buffer
vim.api.nvim_create_autocmd("StdinReadPre", { pattern = "*", command = "let s:std_in=1" })
-- Toggle nvimtree on start
vim.api.nvim_create_autocmd(
    "VimEnter",
    { pattern = "*", command = 'if argc() > 0 || exists("s:std_in") | wincmd p | endif' }
)
