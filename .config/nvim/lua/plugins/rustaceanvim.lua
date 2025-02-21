-- Rust configuration
return {
    "mrcjkb/rustaceanvim",
    version = "^4",
    lazy = false,
    dependencies = {
        "neovim/nvim-lspconfig",
        "nvim-lua/lsp-status.nvim",
    },
}
