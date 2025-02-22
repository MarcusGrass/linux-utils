return {
    "tpope/vim-fugitive",
    config = function()
        local key = require("util.keymap")
        key.mapn("<leader>gfo", ":Git<CR>")
        key.mapn("<leader>gff", ":Git fetch<CR>")
        key.mapn("<leader>gfp", ":Git push<CR>")
        key.mapnfn("<leader>gfr", function()
            vim.cmd(":Git fetch")
            vim.cmd(":Git rebase -i origin/main")
        end)
    end,
}
