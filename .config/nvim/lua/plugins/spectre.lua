return {
    "nvim-pack/nvim-spectre",
    build = "./build.sh",
    keys = {
        {
            "<C-S-r>",
            mode = { "n" },
            function()
                require("spectre").toggle()
            end,
            desc = "Toggle spectre",
        },
    },
    opts = {
        default = {
            replace = {
                cmd = "oxi",
            },
        },
    },
}
