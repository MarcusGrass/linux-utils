local cfg = function()
    require("scrollbar").setup({
        show = true,
        handlers = {
            cursor = true,
            diagnostic = true,
            handle = false,
            gitsigns = true,
        },
        marks = {
            Error = {
                text = { "e", "E" },
            },
            Warn = {
                text = { "e", "W" },
            },
            Info = {
                text = { "e", "I" },
            },
            Hint = {
                text = { "h", "!" },
            },
            Misc = {
                text = { "q", "?" },
            },
            GitAdd = {
                text = ">",
            },
            GitChange = {
                text = "-",
            },
            GitDelete = {
                text = "<",
            },
        },
    })
end
return {
    "petertriho/nvim-scrollbar",
    config = cfg,
}
