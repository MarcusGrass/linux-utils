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
                { "n", "<leader>cf", "<CMD>Git commit <bar> wincmd J<CR>", { desc = "Commit file" } },
                {
                    "n",
                    "<leader>ca",
                    "<CMD>Git commit --amend <bar> wincmd J<CR>",
                    { desc = "Amend last commit with changes in file" },
                },
                -- These are going to split the window, Ideally it'll split to the bottom
                { "n", "<leader>ccs", ":botright Git commit<CR>", { desc = "Commit all staged" } },
                { "n", "<leader>cca", ":botright Git commit --amend<CR>", { desc = "Commit all staged, amend" } },
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
}
