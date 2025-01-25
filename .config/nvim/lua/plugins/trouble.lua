local custom = {
    modes = {
        split_preview = {
            mode = "diagnostics",
            win = { position = "right" },
        },
    },
}
return {
    "folke/trouble.nvim",
    opts = custom,
    cmd = "Trouble",
}
