return {
    "folke/trouble.nvim",
    lazy = false,
    opts = function(_, opts)
        local key = require("util.keymap")
        key.mapn("<leader>tt", ":Trouble split_preview toggle<CR>")
        key.mapn("<leader>to", ":Trouble split_preview focus<CR>")

        return vim.tbl_deep_extend("force", opts or {}, {
            modes = {
                split_preview = {
                    mode = "diagnostics",
                },
            },
        })
    end,
    cmd = "Trouble",
}
