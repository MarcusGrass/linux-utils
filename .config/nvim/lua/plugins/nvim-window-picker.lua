return {
    "s1n7ax/nvim-window-picker",
    name = "window-picker",
    version = "2.*",
    event = "VeryLazy",
    config = function()
        require("window-picker").setup({
            hint = "floating-big-letter",
            selection_chars = "AOEUIDHTNS,.pyfgcrl",
            filter_rules = {
                autoselect_one = false,
                include_current_win = true,
                include_unfocusable_windows = true,
                bo = {
                    filetype = {},
                },
            },
        })
    end,
}
