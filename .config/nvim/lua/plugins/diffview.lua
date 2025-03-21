return {
    "sindrets/diffview.nvim",
    opts = {
        view = {
            -- default = {
            --     layout = "diff3_mixed",
            -- },
            merge_tool = {
                layout = "diff3_mixed",
            },
            -- file_history = {
            --     layout = "diff3_mixed",
            -- },
        },
        keymaps = {
            view = {
                {
                    "n",
                    "<C-ENTER>",
                    require("diffview.config").actions.goto_file_edit,
                    { desc = "Goto file in last accessed tab" },
                },
            },
            file_panel = {
                {
                    "n",
                    "<C-ENTER>",
                    require("diffview.config").actions.goto_file_edit,
                    { desc = "Goto file in last accessed tab" },
                },
            },
            file_history_panel = {
                {
                    "n",
                    "<C-ENTER>",
                    require("diffview.config").actions.goto_file_edit,
                    { desc = "Goto file in last accessed tab" },
                },
            },
        },
    },
    keys = {
        {
            "<leader>do",
            mode = { "n" },
            ":DiffviewOpen<CR>",
            desc = "Open diffview in a new tab",
        },
        {
            "<leader>df",
            mode = { "n" },
            ":DiffviewFileHistory %<CR>",
            desc = "Open diffview for the current file in a new tab",
        },
    },
}
