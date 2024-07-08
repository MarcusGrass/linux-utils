
-- Open diagnostic on cursor hold
vim.api.nvim_create_autocmd("CursorHold", { pattern = "*", command = "lua vim.diagnostic.open_float(nil, { focusable = false })"})

local function open_nvim_tree()
  -- open the tree
  require("nvim-tree.api").tree.open()
end

-- We opened a buffer
vim.api.nvim_create_autocmd("StdinReadPre", { pattern = "*", command = "let s:std_in=1"})
-- Toggle nvimtree on start
vim.api.nvim_create_autocmd({ "VimEnter" }, { callback = open_nvim_tree })
-- Refocus that buffer if present
vim.api.nvim_create_autocmd("VimEnter", { pattern = "*", command = "if argc() > 0 || exists(\"s:std_in\") | wincmd p | endif"})
