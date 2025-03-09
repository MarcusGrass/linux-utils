return {
    "sindrets/diffview.nvim",
    opts = function(_, opts)
        local key = require("util.keymap")
        key.mapn("<leader>do", ":DiffviewOpen<CR>")
        key.mapn("<leader>dc", ":DiffviewClose<CR>")
        key.mapn("<leader>df", ":DiffviewFileHistory %<CR>")

        return vim.tbl_deep_extend("force", opts or {}, {
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
        })
    end,
}
