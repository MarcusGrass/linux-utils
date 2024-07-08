--- Syntax highlighting, language specific
require "nvim-treesitter.configs".setup {
    highlight = {
        enable = true,
    },
    ensure_installed = {
        "lua",
        "toml",
        "bash",
        "json",
        "yaml",
        "python",
        "zig",
        "rust",
    }
}
