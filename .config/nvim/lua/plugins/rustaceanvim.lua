local cfg = function()
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
                    capabilities = shared.lsp_status.capabilities,
                    -- enable clippy on save
                    checkOnSave = true,
                }
            }
        }
    }
end


-- Rust configuration
return { 
    'mrcjkb/rustaceanvim',
    version = "^4",
    lazy = false ,
    config = cfg,
    dependencies = {
        'neovim/nvim-lspconfig',
        'nvim-lua/lsp-status.nvim',
        'nvim-telescope/telescope.nvim',
    }
}

