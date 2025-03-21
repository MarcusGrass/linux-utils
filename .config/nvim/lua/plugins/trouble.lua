return {
    "folke/trouble.nvim",
    lazy = false,
    opts = {
        modes = {
            split_preview = {
                mode = "diagnostics",
            },
        },
    },
    cmd = "Trouble",
    keys = {
        {
            "<leader>tt",
            ":Trouble split_preview toggle<CR>",
        },
        {
            "<leader>to",
            ":Trouble split_preview focus<CR>",
        },
    },
}
