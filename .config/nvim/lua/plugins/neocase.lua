return {
    dir = "/home/gramar/code/rust/neocase",
    keys = {
        {
            "<leader>cc",
            mode = { "n" },
            function()
                return require("neocase").switch_dr()
            end,
            expr = true,
        },
        {
            "<leader>cc",
            mode = { "v" },
            function()
                require("neocase").switch()
            end,
        },
        {
            "<leader>cs",
            mode = { "n", "v" },
            function()
                require("neocase").cycle()
            end,
        },
    },
    opts = {
        cycle = {
            global = {
                "snake",
                "kebab",
                "pascal",
                "scream",
                "camel",
            },
            ft = {
                rust = {
                    "snake",
                    "pascal",
                    "scream",
                },
            },
        },
    },
}
