return {
    "lewis6991/gitsigns.nvim",
    opts = {
        numhl = true,
    },
    keys = {
        {
            "<leader>gsb",
            ":Gitsigns stage_buffer<CR>",
            desc = "git stage the current buffer",
        },
        {
            "<leader>gsh",
            ":Gitsigns stage_hunk<CR>",
            desc = "git stage the current hunk",
        },
        {
            "<leader>guh",
            ":Gitsigns undo_stage_hunk<CR>",
            desc = "git unstage the current hunk",
        },
        {
            "<leader>grb",
            ":Gitsigns reset_buffer<CR>",
            desc = "git reset the current buffer",
        },
        {
            "<leader>grh",
            ":Gitsigns reset_hunk<CR>",
            desc = "git reset the current hunk",
        },
        {
            "<leader>gbi",
            ":Gitsigns blame_line<CR>",
            desc = "git blame the current line",
        },
        {
            "<leader>gbo",
            ":Gitsigns blame<CR>",
            desc = "git blame in gutter",
        },
        {
            "<leader>gse",
            ":Gitsigns select_hunk<CR>",
            desc = "select the current git hunk",
        },
        {
            "<leader>gpi",
            ":Gitsigns preview_hunk_inline<CR>",
            desc = "git preview the current hunk inline",
        },
        {
            "<leader>gph",
            ":Gitsigns preview_hunk<CR>",
            desc = "git preview the current hunk popup",
        },
        {
            "[g",
            ":Gitsigns prev_hunk<CR>",
            desc = "git jump to previous hunk",
        },
        {
            "]g",
            ":Gitsigns next_hunk<CR>",
            desc = "git jump to next hunk",
        },
    },
}
