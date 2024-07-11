local custom = {
    modes = {
        split_preview = {
            mode = "diagnostics",
            preview = {
                type = "split",
                relative = "win",
                position = "right",
                size = 0.3,
            }
        }
    }
}
return {
    "folke/trouble.nvim",
    opts = custom,
    cmd = "Trouble",
}
