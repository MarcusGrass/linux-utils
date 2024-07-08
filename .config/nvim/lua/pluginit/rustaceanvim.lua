local shared = require("pluginit.lsp-shared")
vim.g.rustaceanvim = {
    tools = {
        enable_clippy = true,
    },
    server = {
        auto_attach = true,
        on_attach = shared.lsp_do_attach,
        default_settings = {
            ["rust-analyzer"] = {
                -- enable clippy on save
                checkOnSave = true,
            }
        }
    }
}


