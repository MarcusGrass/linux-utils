local lsp_attach = require("util.lsp_attach")
return {
    "saecki/crates.nvim",
    tag = "stable",
    config = function()
        require("crates").setup {
            lsp = {
                enabled = true,
                actions = true,
                on_attach = function (client, bufnr)
                    lsp_attach.lsp_do_attach(client, bufnr)
                    local lsp_cfg_opts = { noremap = true, silent = true }
                    vim.api.nvim_buf_set_keymap(bufnr, "n", "gf", "<cmd>lua require('crates').show_features_popup()<CR><CMD>lua require('crates').focus_popup()<CR>", lsp_cfg_opts)
                end,
                completion = true,
                hover = true,
            },
            completion = {
                cmp = {
                    enabled = true,
                },
                crates = {
                    enabled = true,
                }
            }
        }
    end,
}
