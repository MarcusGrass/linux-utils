--- Syntax highlighting, language specific
local cfg = function()
    require("nvim-treesitter.configs").setup({
        highlight = {
            enable = true,
        },
        ensure_installed = {
            --- Markdown
            "html",
            "json",
            "jsonnet",
            "markdown",
            "markdown_inline",
            "ron",
            "toml",
            "xml",
            "yaml",
            --- Languages
            "bash",
            "c",
            "cpp",
            "dart",
            "go",
            "java",
            "javascript",
            "lua",
            "python",
            "rust",
            "sql",
            "typescript",
            "zig",
            --- Misc
            "css",
            "csv",
            "cmake",
            "diff",
            "dockerfile",
            "git_config",
            "git_rebase",
            "make",
            "meson",
            "regex",
            "terraform",
            "vim",
            "vimdoc",
        },
    })
end
return {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    tag = "v0.9.2",
    config = cfg,
}
