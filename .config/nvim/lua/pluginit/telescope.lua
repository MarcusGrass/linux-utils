--- Telescope
local actions = require('telescope.actions')
local telescope = require('telescope')
telescope.setup{
    defaults = {
        mappings = {
            n = {
                ["q"] = actions.close
            },
        },
    },
    extensions = {
        fzf = {
            fuzzy = true,
            override_generic_sorter = true,
            override_file_sorter = true,
            case_mode = "smart_case",
        }
    },
}
telescope.load_extension('aerial')
telescope.load_extension('fzf')


