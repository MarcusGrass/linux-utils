local cfg = function()
    local actions = require("telescope.actions")
    local telescope = require("telescope")
    telescope.setup({
        defaults = {
            mappings = {
                i = {},
                n = {
                    ["q"] = actions.close,
                },
            },
            --set_env = { GIT_EXTERNAL_DIFF = '~/.local/bin/difft' },
        },
        extensions = {
            fzf = {
                fuzzy = true,
                override_generic_sorter = true,
                override_file_sorter = true,
                case_mode = "smart_case",
            },
        },
    })
    telescope.load_extension("aerial")
    telescope.load_extension("fzf")
end

return {
    --- Fuzzy find ---
    {
        "MarcusGrass/telescope.nvim",
        branch = "mg/use",
        -- dir = "/home/gramar/code/lua/telescope.nvim",
        -- dev = { true },
        dependencies = {
            "nvim-lua/plenary.nvim",
        },
        config = cfg,
    },
    {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "cmake -S. -Bbuild DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release",
    },
}
