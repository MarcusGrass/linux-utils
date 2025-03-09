return {
    "NeogitOrg/neogit",
    dependencies = {
        "nvim-lua/plenary.nvim",
        "sindrets/diffview.nvim",

        "echasnovski/mini.pick",
    },
    keys = {
        {
            "no",
            mode = "n",
            function()
                require("neogit").open()
            end,
            desc = "open neogit",
        },
        {
            "nb",
            mode = "n",
            function()
                require("neogit").open({ "branch" })
            end,
            desc = "open neogit branch popup",
        },
        {
            "nl",
            mode = "n",
            function()
                require("neogit").open({ "log" })
            end,
            desc = "open neogit log popup",
        },
        {
            "nf",
            mode = "n",
            function()
                require("neogit").open({ "fetch" })
            end,
            desc = "open neogit fetch popup",
        },
    },
}
