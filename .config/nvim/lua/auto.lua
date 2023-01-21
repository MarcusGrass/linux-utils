
-- Format before write on *.rs files
vim.api.nvim_create_autocmd("BufWritePre", { pattern = "*.rs", command = "lua vim.lsp.buf.formatting_sync(nil, 200)" })

-- Open diagnostic on cursor hold
vim.api.nvim_create_autocmd("CursorHold", { pattern = "*", command = "lua vim.diagnostic.open_float(nil, { focusable = false })"})


-- We opened a buffer
vim.api.nvim_create_autocmd("StdinReadPre", { pattern = "*", command = "let s:std_in=1"})
-- Toggle nvimtree on start
vim.api.nvim_create_autocmd("VimEnter", { pattern = "*", command = "NvimTreeToggle"})
-- Refocus that buffer if present
vim.api.nvim_create_autocmd("VimEnter", { pattern = "*", command = "if argc() > 0 || exists(\"s:std_in\") | wincmd p | endif"})