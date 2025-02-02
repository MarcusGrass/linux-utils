local M = {}
local lsp_cfg_opts = { noremap = true, silent = true }
function M.lsp_do_attach(client, bufnr)
    -- Enable completion triggered by <c-x><c-o>
    vim.api.nvim_set_option_value("omnifunc", "v:lua.vim.lsp.omnifunc", {
        buf = bufnr,
    })
    -- Mappings.
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    vim.api.nvim_buf_set_keymap(bufnr, "n", "ga", "<cmd>lua vim.lsp.buf.code_action()<CR>", lsp_cfg_opts)
    vim.api.nvim_buf_set_keymap(bufnr, "n", "gd", '<cmd>lua Snacks.picker.pick("lsp_definitions")<CR>', lsp_cfg_opts)
    vim.api.nvim_buf_set_keymap(
        bufnr,
        "n",
        "gD",
        '<cmd>lua Snacks.picker.pick("lsp_type_definitions")<CR>',
        lsp_cfg_opts
    )
    vim.api.nvim_buf_set_keymap(bufnr, "n", "gr", '<cmd>lua Snacks.picker.pick("lsp_references")<CR>', lsp_cfg_opts)
    vim.api.nvim_buf_set_keymap(
        bufnr,
        "n",
        "gi",
        '<cmd>lua Snacks.picker.pick("lsp_implementations")<CR>',
        lsp_cfg_opts
    )
    vim.api.nvim_buf_set_keymap(
        bufnr,
        "n",
        "<leader>fs",
        '<cmd>lua Snacks.picker.pick("lsp_workspace_symbols")<CR>',
        lsp_cfg_opts
    )
    vim.api.nvim_buf_set_keymap(bufnr, "n", "<C-g>", '<cmd>lua Snacks.picker.pick("lsp_symbols")<CR>', lsp_cfg_opts)
    vim.api.nvim_buf_set_keymap(bufnr, "n", "<S-r>", "<cmd>lua vim.lsp.buf.rename()<CR>", lsp_cfg_opts)
    vim.api.nvim_buf_set_keymap(bufnr, "n", "ge", "<cmd>lua vim.lsp.buf.rename()<CR>", lsp_cfg_opts)
    vim.api.nvim_buf_set_keymap(bufnr, "n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", lsp_cfg_opts)
    vim.api.nvim_buf_set_keymap(bufnr, "n", "<C-k>", "<cmd>lua vim.lsp.buf.signature_help()<CR>", lsp_cfg_opts)
    vim.api.nvim_buf_set_keymap(
        bufnr,
        "n",
        "<leader>wa",
        "<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>",
        lsp_cfg_opts
    )
    vim.api.nvim_buf_set_keymap(
        bufnr,
        "n",
        "<leader>wr",
        "<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>",
        lsp_cfg_opts
    )
    vim.api.nvim_buf_set_keymap(
        bufnr,
        "n",
        "<leader>wl",
        "<cmd>lua vim.lsp.buf.list_workspace_folders()<CR>",
        lsp_cfg_opts
    )
    vim.api.nvim_buf_set_keymap(bufnr, "n", "<space>D", "<cmd>lua vim.lsp.buf.type_definition()<CR>", lsp_cfg_opts)
    -- Custom
    vim.api.nvim_buf_set_keymap(
        bufnr,
        "n",
        "gh",
        "<cmd>lua require('plug-ext/snacks/inlay_hint_picker').snacks_inlay_picker()<CR>",
        lsp_cfg_opts
    )
end

return M
