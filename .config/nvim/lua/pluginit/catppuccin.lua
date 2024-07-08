require("catppuccin").setup({
    flavour = "mocha",
    integrations = {
        aerial = true,
        barbar = true,
        cmp = true,
        diffview = true,
        gitsigns = true,
        neotest = true,
        nvimtree = true,
        telescope = {
            enabled = true,
        },
        treesitter = true,
    },
})

vim.cmd.colorscheme "catppuccin"
