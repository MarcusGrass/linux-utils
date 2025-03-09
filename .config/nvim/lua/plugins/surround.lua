return {
    "kylechui/nvim-surround",
    version = "*", -- Use for stability; omit to use `main` branch for the latest features
    event = "VeryLazy",
    opts = {
        keymaps = {
            insert = "<C-s>",
            insert_line = "<C-S-s>",
            normal = "ysn",
            normal_cur = "yss",
            normal_line = "ysl",
            visual = "yss",
            visual_line = "ysl",
            delete = "yd",
            change = "yc",
            change_line = "yl",
        },
    },
}
