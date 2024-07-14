local cfg = function()
    require("catppuccin").setup({
        flavour = "mocha",
        integrations = {
            aerial = true,
            barbar = true,
            cmp = true,
            diffview = true,
            gitsigns = true,
            lsp_trouble = true,
            lsp_saga = true,
            neotest = true,
            nvimtree = true,
            telescope = {
                enabled = true,
            },
            treesitter = true,
        },
    })
    vim.cmd.colorscheme "catppuccin"
end

--- Theme ---
return {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = cfg,
}

