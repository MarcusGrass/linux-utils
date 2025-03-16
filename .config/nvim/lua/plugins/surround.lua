return {
    "kylechui/nvim-surround",
    version = "*", -- Use for stability; omit to use `main` branch for the latest features
    event = "VeryLazy",
    opts = {
        keymaps = {
            insert = "<C-s>",
            insert_line = "<C-S-s>",
            normal = "<leader>ysn",
            normal_cur = "<leader>yss",
            normal_line = "<leader>ysl",
            visual = "<leader>yss",
            visual_line = "<leader>ysl",
            delete = "<leader>yd",
            change = "<leader>yc",
            change_line = "<leader>yl",
        },
    },
}
