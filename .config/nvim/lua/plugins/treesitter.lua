--- Syntax highlighting, language specific
local cfg = function()
    require("nvim-treesitter.configs").setup({
        highlight = {
            enable = true,
        },
        ensure_installed = {
            "lua",
            "toml",
            "bash",
            "markdown",
            "markdown_inline",
            "json",
            "yaml",
            "python",
            "zig",
            "rust",
        },
    })
end
return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    tag = "v0.9.2",
    config = cfg,
}
