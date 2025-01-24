--- Lsp setup
---

local shared = {}
shared.nvim_lsp = require("lspconfig")
shared.lsp_status = require("lsp-status")

shared.lsp_status.register_progress()
local fmt_augroup = vim.api.nvim_create_augroup("LspFormatting", {})

local lsp_cfg_opts = { noremap = true, silent = true }
function shared.lsp_do_attach(client, bufnr)
    -- Enable completion triggered by <c-x><c-o>
    vim.api.nvim_set_option_value("omnifunc", "v:lua.vim.lsp.omnifunc", {
        buf = bufnr,
    })
    -- Mappings.
    -- See `:help vim.lsp.*` for documentation on any of the below functions
    vim.api.nvim_buf_set_keymap(bufnr, "n", "ga", "<cmd>lua vim.lsp.buf.code_action()<CR>", lsp_cfg_opts)
    vim.api.nvim_buf_set_keymap(
        bufnr,
        "n",
        "gA",
        "<cmd>lua require('telescope.builtin').lsp_range_code_actions()<CR>",
        lsp_cfg_opts
    )
    vim.api.nvim_buf_set_keymap(
        bufnr,
        "n",
        "gd",
        "<cmd>lua require('telescope.builtin').lsp_definitions()<CR>",
        lsp_cfg_opts
    )
    vim.api.nvim_buf_set_keymap(bufnr, "n", "gD", "<cmd>lua vim.lsp.buf.declaration()<CR>", lsp_cfg_opts)
    vim.api.nvim_buf_set_keymap(
        bufnr,
        "n",
        "gr",
        "<cmd>lua require('telescope.builtin').lsp_references()<CR>",
        lsp_cfg_opts
    )
    vim.api.nvim_buf_set_keymap(
        bufnr,
        "n",
        "gi",
        "<cmd>lua require('telescope.builtin').lsp_implementations()<CR>",
        lsp_cfg_opts
    )
    vim.api.nvim_buf_set_keymap(
        bufnr,
        "n",
        "<C-S-g>",
        "<cmd>lua require('telescope.builtin').lsp_dynamic_workspace_symbols()<CR>",
        lsp_cfg_opts
    )
    vim.api.nvim_buf_set_keymap(
        bufnr,
        "n",
        "<C-g>",
        "<cmd>lua require('telescope.builtin').lsp_workspace_symbols()<CR>",
        lsp_cfg_opts
    )
    vim.api.nvim_buf_set_keymap(
        bufnr,
        "n",
        "g0",
        "<cmd>lua require('telescope.builtin').lsp_document_symbols()<CR>",
        lsp_cfg_opts
    )
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
    vim.api.nvim_buf_set_keymap(bufnr, "n", "gh", "<cmd>lua require('util.telescope_inlay_hint_picker').inlay_picker()<CR>", lsp_cfg_opts)

    if client.supports_method("textDocument/formatting") then
        vim.api.nvim_clear_autocmds({ group = fmt_augroup, buffer = bufnr })
        vim.api.nvim_create_autocmd("BufWritePre", {
            group = fmt_augroup,
            buffer = bufnr,
            callback = function()
                vim.lsp.buf.format()
            end,
        })
    end
    shared.lsp_status.on_attach(client)
end

return shared
