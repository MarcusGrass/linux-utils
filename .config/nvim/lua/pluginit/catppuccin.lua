require("catppuccin").setup({
    flavour = "latte",
    integrations = {
        aerial = true,
        barbar = true,
        cmp = true,
        diffview = true,
        gitgutter = true,
        neotest = true,
        nvimtree = true,
        telescope = {
            enabled = true,
        },
        treesitter = true,
    },
})

vim.cmd.colorscheme = "catppuccin"

