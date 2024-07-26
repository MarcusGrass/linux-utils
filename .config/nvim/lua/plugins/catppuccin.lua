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
        color_overrides = {
            -- Increase contrast slightly for most colors
            -- Green more green, mauve more purple, etc
            mocha = {
                -- Mauve lavender and blue are often together,
                -- in rust they become pub(mauve) var_name(lavender), fn_name(blue), these are often seen together
                lavender = "#b9b4fe", -- "#b4befe",
                blue = "#89a9fa", -- "#89b4fa",
                mauve = "#bf8bfc", -- "#cba6f7",
                -- Make strings stand out more
                green = "#8ede87", -- "#a6e3a1",
                peach = "#f7a877", -- "#fab387",
                -- Structs defs, more yellow
                yellow = "#f5da9f", -- "#f9e2af",
                -- General text, needs to contrast with other's too blue in general, inrease whiteness
                text = "#d5dcf2", -- "#cdd6f4",
                -- Generally don't like teal, doesn't matter much though, move towards green
                teal = "#94e2bc", -- "#94e2d5",
                -- Var names in rust
                maroon = "#eba0bb", -- "#eba0ac",
                -- Self var, needsto contrast with above
                red = "#f38b92", -- "#f38ba8",
                -- Traits, often seen with the yellow structs, needs more contrast, move towards red
                flamingo = "#f0bdbd", -- "#f2cdcd"
            },
        },
    })
    vim.cmd.colorscheme("catppuccin")
end

--- Theme ---
return {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    config = cfg,
}
