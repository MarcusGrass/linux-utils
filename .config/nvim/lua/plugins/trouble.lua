local custom = {
    modes = {
        split_preview = {
            mode = "diagnostics",
        },
    },
}
return {
    "folke/trouble.nvim",
    opts = custom,
    cmd = "Trouble",
}
