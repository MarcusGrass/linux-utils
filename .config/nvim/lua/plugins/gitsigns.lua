return {
    "lewis6991/gitsigns.nvim",
    opts = function(_, opts)
        local key = require("util.keymap")
        key.mapn("]g", ":Gitsigns next_hunk<CR>")
        key.mapn("[g", ":Gitsigns prev_hunk<CR>")
        key.mapn("<leader>gph", ":Gitsigns preview_hunk<CR>")
        key.mapn("<leader>gpi", ":Gitsigns preview_hunk_inline<CR>")
        key.mapn("<leader>gsh", ":Gitsigns select_hunk<CR>")
        key.mapn("<leader>gbo", ":Gitsigns blame<CR>")
        key.mapn("<leader>gbi", ":Gitsigns blame_line<CR>")
        key.mapn("<leader>grh", ":Gitsigns reset_hunk<CR>")
        key.mapn("<leader>grb", ":Gitsigns reset_buffer<CR>")
        key.mapn("<leader>gsh", ":Gitsigns stage_hunk<CR>")
        key.mapn("<leader>gsb", ":Gitsigns stage_buffer<CR>")

        return vim.tbl_deep_extend("force", opts or {}, {
            numhl = true,
        })
    end,
}
