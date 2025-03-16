return {
    "NeogitOrg/neogit",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "sindrets/diffview.nvim",

        "echasnovski/mini.pick",
    },
    keys = {
        {
            "<leader>neo",
            mode = "n",
            function()
                require("neogit").open()
            end,
            desc = "open neogit",
        },
    },
}
